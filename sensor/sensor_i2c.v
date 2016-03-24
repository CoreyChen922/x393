/*******************************************************************************
 * Module: sensor_i2c
 * Date:2015-05-10  
 * Author: Andrey Filippov     
 * Description: i2c write-only sequencer to control image sensor
 *
 * Copyright (c) 2015 Elphel, Inc.
 * sensor_i2c.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  sensor_i2c.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *
 * Additional permission under GNU GPL version 3 section 7:
 * If you modify this Program, or any covered work, by linking or combining it
 * with independent modules provided by the FPGA vendor only (this permission
 * does not extend to any 3-rd party modules, "soft cores" or macros) under
 * different license terms solely for the purpose of generating binary "bitstream"
 * files and/or simulating the code, the copyright holders of this Program give
 * you the right to distribute the covered work without those independent modules
 * as long as the source code for them is available from the FPGA vendor free of
 * charge, and there is no dependence on any encrypted modules for simulating of
 * the combined code. This permission applies to you if the distributed code
 * contains all the components and scripts required to completely simulate it
 * with at least one of the Free Software programs.
 *******************************************************************************/
`timescale 1ns/1ps

module  sensor_i2c#(
    parameter SENSI2C_ABS_ADDR =       'h410,
    parameter SENSI2C_REL_ADDR =       'h420,
    parameter SENSI2C_ADDR_MASK =      'h7f0, // both for SENSI2C_ABS_ADDR and SENSI2C_REL_ADDR
    parameter SENSI2C_CTRL_ADDR =      'h402,
    parameter SENSI2C_CTRL_MASK =      'h7fe,
    parameter SENSI2C_CTRL =           'h0,
    parameter SENSI2C_STATUS =         'h1,
    parameter SENSI2C_STATUS_REG =     'h20,
    // Control register bits
    parameter SENSI2C_CMD_TABLE =       29, // [29]: 1 - write to translation table (ignore any other fields), 0 - write other fields
    parameter SENSI2C_CMD_TAND =        28, // [28]: 1 - write table address (8 bits), 0 - write table data (28 bits)
    parameter SENSI2C_CMD_RESET =       14, // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
    parameter SENSI2C_CMD_RUN =         13, // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
    parameter SENSI2C_CMD_RUN_PBITS =    1,
    
    parameter SENSI2C_CMD_FIFO_RD =      3, // advance I2C read data FIFO by 1  
    parameter SENSI2C_CMD_ACIVE =        2, // [2] - SENSI2C_CMD_ACIVE_EARLY0, SENSI2C_CMD_ACIVE_SDA
    parameter SENSI2C_CMD_ACIVE_EARLY0 = 1, // release SDA==0 early if next bit ==1
    parameter SENSI2C_CMD_ACIVE_SDA =    0,  // drive SDA=1 during the second half of SCL=1

    //i2c page table bit fields
    parameter SENSI2C_TBL_RAH =          0, // high byte of the register address 
    parameter SENSI2C_TBL_RAH_BITS =     8,
    parameter SENSI2C_TBL_RNWREG =       8, // read register (when 0 - write register
    parameter SENSI2C_TBL_SA =           9, // Slave address in write mode
    parameter SENSI2C_TBL_SA_BITS =      7,
    parameter SENSI2C_TBL_NBWR =        16, // number of bytes to write (1..10)
    parameter SENSI2C_TBL_NBWR_BITS =    4,
    parameter SENSI2C_TBL_NBRD =        16, // number of bytes to read (1 - 8) "0" means "8"
    parameter SENSI2C_TBL_NBRD_BITS =    3,
    parameter SENSI2C_TBL_NABRD =       19, // number of address bytes for read (0 - 1 byte, 1 - 2 bytes)
    parameter SENSI2C_TBL_DLY =         20, // bit delay (number of mclk periods in 1/4 of SCL period)
    parameter SENSI2C_TBL_DLY_BITS=      8
)(
    input         mrst,         // @ posedge mclk
    input         mclk,         // global clock, half DDR3 clock, synchronizes all I/O through the command port
    input   [7:0] cmd_ad,       // byte-serial command address/data (up to 6 bytes: AL-AH-D0-D1-D2-D3 
    input         cmd_stb,      // strobe (with first byte) for the command a/d
// status will {frame_num[3:0],busy,sda,scl} - read outside of this module?
// Or still use status here but program it in other bits?
// increase address range over 5 bits?
// borrow 0x1e?    
    output  [7:0] status_ad,   // status address/data - up to 5 bytes: A - {seq,status[1:0]} - status[2:9] - status[10:17] - status[18:25]
    output        status_rq,   // input request to send status downstream
    input         status_start,// Acknowledge of the first status packet byte (address)
    input         frame_sync,  // @posedge mclk increment/reset frame number 
    input         sda_in,      // i2c SDA input
    input         scl_in,      // i2c SCL input
    output        scl_out,     // i2c SCL output
    output        sda_out,     // i2c SDA output
    output        scl_en,      // i2c SCL enable
    output        sda_en       // i2c SDA enable
//    output        busy,
//    output  [3:0] frame_num

);
// TODO: Make sure that using more than 64 commands will just send them during next frame, not loose?
// 0x0..0xf write directly to the frame number [3:0] modulo 16, except if you write to the frame
//          "just missed" - in that case data will go to the current frame.
// 0x10 - write i2c commands to be sent ASAP
// 0x11 - write i2c commands to be sent after the next frame starts 
// ... 
// 0x1e - write i2c commands to be sent after the next 14 frames start
// 0x1e - program status? Or
// 0x1f - control register:
//     [14] -   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
//     [13:12] - 3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
//     [11] -   if 1, use [10:9] to set command bytes to send after slave address (0..3)
//     [10:9] - number of bytes to send, valid if [11] is set
//     [8]    - set duration of quarter i2c cycle in system clock cycles - nominal value 100 (0x64)
//     [7:0]  - duration of quater i2c cycle (applied if [8] is set)

     wire           we_abs;
     wire           we_rel;
     wire           we_cmd;
     wire           wen;
     wire    [31:0] di;
     wire     [3:0] wa; 
//     wire           busy;        // busy (do not use software i2i)
     
     
//    reg    [4:0]  wen_d; // [0] - not just fifo, but any PIO writes, [1] and next - filtered for FIFO only
//     reg    [3:0]  wen_d; // [0] - not just fifo, but any PIO writes, [1] and next - filtered for FIFO only
//     reg    [3:0]  wad; 
     reg   [31:0]  di_r; // 32 bit command takes 6 cycles, so di_r can hold data for up to this long
//     reg   [15:0]  di_1;
//     reg   [15:0]  di_2;
//     reg   [15:0]  di_3;
     reg    [3:0]  wpage0;     // FIFO page where ASAP writes go
     reg    [3:0]  wpage_prev;     // unused page, currently being cleared
     reg    [3:0]  page_r;     // FIFO page where current i2c commands are taken from
     
     reg    [3:0]  wpage_wr;    // FIFO page where current write goes (reading from write address) 
     reg    [1:0]  wpage0_inc; // increment wpage0 (after frame sync or during reset)
     reg           reset_cmd;
//     reg           dly_cmd;
//     reg           bytes_cmd;
     reg           run_cmd;
     reg           twe;
     reg           active_cmd;
     reg           active_sda;
     reg           early_release_0;
     reg           reset_on;   // reset FIFO in progress
//     reg    [1:0]  i2c_bytes;
//     reg    [7:0]  i2c_dly;
     reg           i2c_enrun;     // enable i2c
     reg           we_fifo_wp; // enable writing to fifo write pointer memory
     reg           req_clr;    // request for clearing fifo_wp (delay frame sync if previous is not yet sent out), also used for clearing all
//     wire          is_ctl= (wad[3:0]==4'hf);
//     wire          is_abs= (wad[3]==0);
     wire          pre_wpage0_inc; // ready to increment
     
     wire   [3:0]  frame_num=wpage0[3:0];
//fifo write pointers (dual port distributed RAM)
     reg    [5:0]  fifo_wr_pointers_ram [0:15]; // dual ported read?
     wire   [5:0]  fifo_wr_pointers_outw; // pointer dual-ported RAM - write port out, valid next after command
     wire   [5:0]  fifo_wr_pointers_outr; // pointer dual-ported RAM - read port out

     reg    [5:0]  fifo_wr_pointers_outw_r;
     reg    [5:0]  fifo_wr_pointers_outr_r;
// command i2c fifo (RAMB16_S9_S18)
     reg    [9:0]  i2c_cmd_wa; // wite address for the current pair of 16-bit data words - changed to a single 32-bit word
                               // {page[3:0],word[5:0],MSW[0]}
     reg           i2c_cmd_we; // write enable to blockRAM

     reg    [1:0]  page_r_inc; // increment page_r[2:0]; - signal and delayed version
     reg    [5:0]  rpointer;    // FIFO read pointer for current page

     reg           i2c_start; // initiate i2c register write sequence
     wire          i2c_run;   // i2c sequence is in progress (early end)
     reg           i2c_run_d;   // i2c sequence is in progress (early end)
//     wire          i2c_busy;  // i2c sequence is in progress (until bus is free and stop finished)
     wire   [1:0]  byte_number;  // byte number to send next (3-2-1-0)
     wire   [1:0]  seq_mem_re;
     wire   [7:0]  i2c_data;
     wire   [7:0]  i2c_rdata;        // data read over i2c bus
     wire          i2c_rvalid;      // i2c_rdata single-cycle strobe
     wire          i2c_fifo_nempty; // i2c read fifo has data
     reg           i2c_fifo_rd;     // read i2c FIFO
     reg           i2c_fifo_cntrl;  // i2c FIFO odd/even byte
     wire   [7:0]  i2c_fifo_dout;   // i2c FIFO data out
     reg           busy;
     reg    [3:0]  busy_cntr;
     
     wire          set_ctrl_w;
     wire          set_status_w;

     reg            [1:0] wen_r;
//     reg            [1:0] wen_fifo;
     reg            wen_fifo; // [1] was not used - we_fifo_wp was used instead

     
     assign set_ctrl_w = we_cmd && ((wa & ~SENSI2C_CTRL_MASK) == SENSI2C_CTRL );// ==0
     assign set_status_w = we_cmd && ((wa & ~SENSI2C_CTRL_MASK) == SENSI2C_STATUS );// ==0
     assign  pre_wpage0_inc = (!wen && !(|wen_r) && !wpage0_inc[0]) && (req_clr || reset_on) ;

     assign  fifo_wr_pointers_outw = fifo_wr_pointers_ram[wpage_wr[3:0]]; // valid next after command
     assign  fifo_wr_pointers_outr = fifo_wr_pointers_ram[page_r[3:0]];
     

     assign         wen=set_ctrl_w || we_rel || we_abs; //remove set_ctrl_w?
     
     assign scl_en = i2c_enrun;
     
     
    reg alive_fs;
    always @ (posedge mclk) begin
        if    (set_status_w) alive_fs <= 0;
        else if (frame_sync) alive_fs <= 1;
    end
    

    cmd_deser #(
        .ADDR        (SENSI2C_ABS_ADDR),
        .ADDR_MASK   (SENSI2C_ADDR_MASK),
        .NUM_CYCLES  (6),
        .ADDR_WIDTH  (4),
        .DATA_WIDTH  (32),
        .ADDR1       (SENSI2C_REL_ADDR),
        .ADDR_MASK1  (SENSI2C_ADDR_MASK),
        .ADDR2       (SENSI2C_CTRL_ADDR),
        .ADDR_MASK2  (SENSI2C_CTRL_MASK)
    ) cmd_deser_sens_i2c_i (
        .rst         (1'b0), // rst), // input
        .clk         (mclk), // input
        .srst        (mrst), // input
        .ad          (cmd_ad), // input[7:0] 
        .stb         (cmd_stb), // input
        .addr        (wa), // output[15:0] 
        .data        (di), // output[31:0] 
        .we          ({we_cmd,we_rel,we_abs}) // output
    );

    status_generate #(
        .STATUS_REG_ADDR(SENSI2C_STATUS_REG),
        .PAYLOAD_BITS(7+3+10) // STATUS_PAYLOAD_BITS)
    ) status_generate_sens_i2c_i (
        .rst        (1'b0), // rst), // input
        .clk        (mclk), // input
        .srst       (mrst), // input
        .we         (set_status_w), // input
        .wd         (di[7:0]), // input[7:0] 
        .status     ({reset_on, req_clr,
                      frame_num[3:0],
                      alive_fs,busy, i2c_fifo_cntrl, i2c_fifo_nempty,
                      i2c_fifo_dout[7:0],
                      sda_in, scl_in}), // input[25:0] 
        .ad         (status_ad), // output[7:0] 
        .rq         (status_rq), // output
        .start      (status_start) // input
    );
    fifo_same_clock #(
        .DATA_WIDTH(8),
        .DATA_DEPTH(4)
    ) fifo_same_clock_i2c_rdata_i (
        .rst        (1'b0),             // input
        .clk        (mclk),            // input
        .sync_rst   (mrst),            // input
        .we         (i2c_rvalid),      // input
        .re         (i2c_fifo_rd),     // input
        .data_in    (i2c_rdata),       // input[15:0] 
        .data_out   (i2c_fifo_dout),   // output[15:0] 
        .nempty     (i2c_fifo_nempty), // output
        .half_full  () // output reg 
    );
     
    always @ (posedge mclk) begin
        if (wen) di_r <= di; // 32 bit command takes 6 cycles, so di_r can hold data for up to this long
        wen_r    <= {wen_r[0],wen}; // is it needed?      
//        wen_fifo <= {wen_fifo[0],we_rel || we_abs};      
        wen_fifo <= we_rel || we_abs;              
         
// signals related to writing to i2c FIFO
// delayed versions of address, data write strobe
//       if (wen)   wad [ 3:0] <= wa[ 3:0];
//       if (wen || wen_d[0]) di_1[15:0] <= di[15:0];
//       di_2[15:0] <= di_1[15:0];
//       di_3[15:0] <= di_2[15:0];
//      wen_d[4:0] <= {wen_d[3:1],wen_d[0] && !is_ctl,wen};
//        wen_d[3:0] <= {wen_d[2:1],wen_d[0] && !is_ctl,wen};
// software i2c signals     
//        wen_i2c_soft <= wen_d[0] && is_ctl;

// decoded commands, valid next cycle after we_*     
        reset_cmd <=   set_ctrl_w && di[SENSI2C_CMD_RESET] && !di[SENSI2C_CMD_TABLE];
        run_cmd <=     set_ctrl_w && di[SENSI2C_CMD_RUN]   && !di[SENSI2C_CMD_TABLE];
        active_cmd <=  set_ctrl_w && di[SENSI2C_CMD_ACIVE] && !di[SENSI2C_CMD_TABLE];
        twe <=         set_ctrl_w && di[SENSI2C_CMD_TABLE];
        i2c_fifo_rd <= set_ctrl_w && di[SENSI2C_CMD_FIFO_RD] && !di[SENSI2C_CMD_TABLE];
        
        if    (reset_cmd || mrst) i2c_enrun <= 1'b0;
        else if (run_cmd)         i2c_enrun <= di_r[SENSI2C_CMD_RUN - 1 -: SENSI2C_CMD_RUN_PBITS]; // [12];
        
        if (active_cmd) begin
            early_release_0 <= di_r[SENSI2C_CMD_ACIVE_EARLY0];
            active_sda <=      di_r[SENSI2C_CMD_ACIVE_SDA];
        end

// write pointer memory
      wpage0_inc <= {wpage0_inc[0],pre_wpage0_inc};
      // reset pointers in all 16 pages:      
      reset_on <= reset_cmd  || (reset_on && !(wpage0_inc[0] && ( wpage0[3:0] == 4'hf)));
      // request to clear pointer(s)? for one page - during reset or delayed frame sync (if previous was not finished)
      req_clr  <= frame_sync || (req_clr && !wpage0_inc[0]);

      if      (reset_cmd)     wpage0 <= 0;
//      else if (frame_0)    wpage0 <= 0;
      else if (wpage0_inc[0]) wpage0<=wpage0+1;
      
      if      (reset_cmd)     wpage_prev<=4'hf;
      else if (wpage0_inc[0]) wpage_prev<=wpage0;
      
      
      if      (we_abs)        wpage_wr <= ((wa==wpage_prev)? wpage0[3:0] : wa);
      else if (we_rel)        wpage_wr <= wpage0+wa;
      else if (wpage0_inc[0]) wpage_wr <= wpage_prev; // only for erasing?
      
      we_fifo_wp <= wen_fifo || wpage0_inc[0];
      
      
      if (wen_fifo)  fifo_wr_pointers_outw_r[5:0] <= fifo_wr_pointers_outw[5:0];
       
       // write to dual-port pointer memory
      if (we_fifo_wp) fifo_wr_pointers_ram[wpage_wr] <= wpage0_inc[1]? 6'h0:(fifo_wr_pointers_outw_r[5:0]+1); 
        
      fifo_wr_pointers_outr_r[5:0] <= fifo_wr_pointers_outr[5:0]; // just register distri
      if (wen_fifo) i2c_cmd_wa <= {wpage_wr[3:0],fifo_wr_pointers_outw[5:0]};
      i2c_cmd_we    <=  !reset_cmd && wen_fifo; // [0];
        
// signals related to reading from i2c FIFO
      if      (reset_on)      page_r<=0;
      else if (page_r_inc[0]) page_r<=page_r+1;


      if      (reset_cmd || page_r_inc[0])  rpointer[5:0] <= 6'h0;
      else if (i2c_run_d && ! i2c_run)      rpointer[5:0] <= rpointer[5:0] + 1;

      i2c_start <= i2c_enrun && !i2c_run && !i2c_run_d && !i2c_start && (rpointer[5:0]!= fifo_wr_pointers_outr_r[5:0]) && !(|page_r_inc);
      page_r_inc[1:0] <= {page_r_inc[0],
                           !i2c_run &&                              // not i2c in progress
                           !page_r_inc[0] &&                        // was not incrementing in previous cycle
                           (rpointer == fifo_wr_pointers_outr_r) && // nothing left for this page
                           (page_r !=  wpage0)};                    // not already the write-open current page
      if (wen)             busy_cntr <= 4'hf;
      else if (|busy_cntr) busy_cntr <= busy_cntr-1;
        
      busy <= (i2c_enrun && ((rpointer[5:0]!= fifo_wr_pointers_outr_r[5:0]) || (page_r!=wpage0))) ||
                (|busy_cntr) ||
                  i2c_run ||
                  reset_on;
                  
      i2c_run_d <= i2c_run;
     
     if      (mrst)        i2c_fifo_cntrl <= 0;
     else if (i2c_fifo_rd) i2c_fifo_cntrl <= ~i2c_fifo_cntrl;
     
     
    end
    
    sensor_i2c_prot  #(
        .SENSI2C_TBL_RAH         (SENSI2C_TBL_RAH), // high byte of the register address 
        .SENSI2C_TBL_RAH_BITS    (SENSI2C_TBL_RAH_BITS),
        .SENSI2C_TBL_RNWREG      (SENSI2C_TBL_RNWREG), // read register (when 0 - write register
        .SENSI2C_TBL_SA          (SENSI2C_TBL_SA), // Slave address in write mode
        .SENSI2C_TBL_SA_BITS     (SENSI2C_TBL_SA_BITS),
        .SENSI2C_TBL_NBWR        (SENSI2C_TBL_NBWR), // number of bytes to write (1..10)
        .SENSI2C_TBL_NBWR_BITS   (SENSI2C_TBL_NBWR_BITS),
        .SENSI2C_TBL_NBRD        (SENSI2C_TBL_NBRD), // number of bytes to read (1 - 8) "0" means "8"
        .SENSI2C_TBL_NBRD_BITS   (SENSI2C_TBL_NBRD_BITS),
        .SENSI2C_TBL_NABRD       (SENSI2C_TBL_NABRD), // number of address bytes for read (0 - 1 byte, 1 - 2 bytes)
        .SENSI2C_TBL_DLY         (SENSI2C_TBL_DLY),   // bit delay (number of mclk periods in 1/4 of SCL period)
        .SENSI2C_TBL_DLY_BITS    (SENSI2C_TBL_DLY_BITS)
    ) sensor_i2c_prot_i(
        .mrst            (mrst),            // input
        .mclk            (mclk),            // input
        .i2c_rst         (reset_cmd),       // input
        .i2c_start       (i2c_start),       // input
        .active_sda      (active_sda),      // input
        .early_release_0 (early_release_0), // input
        .tand            (di_r[SENSI2C_CMD_TAND]),        // input
        .td              (di_r[SENSI2C_CMD_TAND-1:0]),      // input[27:0] 
        .twe             (twe),             // input
        .sda_in          (sda_in),          // input
        .sda             (sda_out),         // output
        .sda_en          (sda_en),          // output
        .scl             (scl_out),         // output
        .i2c_run         (i2c_run),         // output reg 
        .i2c_busy        (), //i2c_busy),   // output reg 
        .seq_mem_ra      (byte_number),     // output[1:0] reg 
        .seq_mem_re      (seq_mem_re),      // output[1:0] 
        .seq_rd          (i2c_data),        // input[7:0] 
        .rdata           (i2c_rdata),       // output[7:0] 
        .rvalid          (i2c_rvalid)       // output
    );
    
    
    
    ram_var_w_var_r #(
        .REGISTERS(1), // try to delay i2c_byte_start by one more cycle
        .LOG2WIDTH_WR(5),
        .LOG2WIDTH_RD(3)
    ) i_fifo (
        .rclk     (mclk), // input
        .raddr    ({page_r[3:0],  rpointer[5:0], byte_number[1:0]}), // input[11:0] 
        .ren      (seq_mem_re[0]), // input
        .regen    (seq_mem_re[1]), // input
        .data_out (i2c_data[7:0]), // output[7:0] 
        .wclk     (mclk), // input
        .waddr    (i2c_cmd_wa), // input[9:0] 
        .we       (i2c_cmd_we), // input
        .web      (8'hff), // input[7:0] 
        .data_in  (di_r) // input[31:0] 
    );

endmodule

