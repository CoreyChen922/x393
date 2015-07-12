/*******************************************************************************
 * Module: sens_gamma
 * Date:2015-05-24  
 * Author: Andrey Filippov     
 * Description: table based piecewise-linear conversion of 16 -> 8 bit data
 *
 * Copyright (c) 2015 Elphel, Inc.
 * sens_gamma.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  sens_gamma.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
`timescale 1ns/1ps

module  sens_gamma #(
    parameter SENS_GAMMA_NUM_CHN =     3, // number of subchannels for his sensor ports (1..4)
    parameter SENS_GAMMA_BUFFER =      0, // 1 - use "shadow" table for clean switching, 0 - single table per channel
    parameter SENS_GAMMA_ADDR =        'h338,
    parameter SENS_GAMMA_ADDR_MASK =   'h7fc,
    parameter SENS_GAMMA_CTRL =        'h0,
    parameter SENS_GAMMA_ADDR_DATA =   'h1, // bit 20 ==1 - table address, bit 20==0 - table data (18 bits)
    parameter SENS_GAMMA_HEIGHT01 =    'h2, // bits [15:0] - height minus 1 of image 0, [31:16] - height-1 of image1
    parameter SENS_GAMMA_HEIGHT2 =     'h3, // bits [15:0] - height minus 1 of image 2 ( no need for image 3)
//    parameter SENS_GAMMA_STATUS =      'h1,
//    parameter SENS_GAMMA_TADDR =       'h2,
//    parameter SENS_GAMMA_TDATA =       'h3, // 1.. 2^16, 0 - use HACT????
//    parameter SENS_GAMMA_STATUS_REG =  'h32
    parameter    SENS_GAMMA_MODE_WIDTH = 5, // does not include trig
    parameter    SENS_GAMMA_MODE_BAYER = 0,
    parameter    SENS_GAMMA_MODE_PAGE =  2,
    parameter    SENS_GAMMA_MODE_EN =    3,
    parameter    SENS_GAMMA_MODE_REPET = 4,
    parameter    SENS_GAMMA_MODE_TRIG =  5
) (
    input         rst,
    input         pclk,   // global clock input, pixel rate (96MHz for MT9P006)
    //input         en,     //    @(posedge pclk)      // Enable. Should go active before or with the first hact going active.
                                       // when low will also reset MSB of addresses - buffer page for ping-pong access.
                                       // SDRAM ch1 should be enabled earler to have data ready in the buffer
                                       // When going low will mask input hact, finish pending data->SDRAM and quit
                                       // So normal sequence is:
                                       //   1 - program (end enable) SDRAM channels 0 and 1, channel 1 will start reading
                                       //   2 - wait for frame sync and enable "en"
                                       //   3 (optional) - after frame is over (before the first hact of the next one)
                                       //      turn "en" off. If needed to restart - go to step 1 to keep buffer pages in sync.
    
    input  [15:0] pxd_in, //    @(posedge pclk)
    input         hact_in,
    input         sof_in,    // start of frame, single pclk, input
    input         eof_in,   // end of frame
    input         trig_in,  // external trigger to process a single frame. May be unused (grounded) as there
                            // is a software trigger option implemented
    output [7:0]  pxd_out,
    output        hact_out,
    output        sof_out,    // start of frame, single pclk, output
    output        eof_out,   // end of frame

    // programming interface
    input         mclk,        // global clock, half DDR3 clock, synchronizes all I/O through the command port
    input   [7:0] cmd_ad,      // byte-serial command address/data (up to 6 bytes: AL-AH-D0-D1-D2-D3 
    input         cmd_stb     // strobe (with first byte) for the command a/d
);
    wire    [1:0] cmd_a;
    wire   [31:0] cmd_data;
    wire          cmd_we;
//    wire          set_status_w;
    wire          set_ctrl_w;
    wire          set_taddr_w;
    wire          set_tdata_w;
    wire          set_height01_w;
    wire          set_height2_w;
    reg           set_tdata_r;
    reg    [3:0]  set_tdata_ram;
    reg    [17:0] tdata;
//    wire          set_taddr_data_w;
    reg    [12:0] taddr; // to high bits - select channnel (in buffered mode), in nion-buffered - 1 bit less, only 10 bits each table
    reg [SENS_GAMMA_MODE_WIDTH-1:0] mode=0;
    reg [SENS_GAMMA_MODE_WIDTH-1:0] mode_mclk=0;
    
    reg    [15:0] height0_m1; // set @ posedge mclk, used at pclk, but should be OK
    reg    [15:0] height1_m1;
    reg    [15:0] height2_m1;
    
    wire    [1:0] bayer;
    wire          table_page; //part of the mode register
    wire          en_input;
    wire          repet_mode;
    
    reg     [1:0] sensor_subchn; // select sensor from the multiplexed ones
    reg           sof_r;
    reg           inc_line;
    reg    [15:0] line_cntr;     // count image lines to switch to next subchannels
    wire    [3:0] table_re;
    reg     [3:0] table_regen;
    wire    [1:0] ram_chn;
    reg     [1:0] ram_chn_d;
    reg     [1:0] ram_chn_d2;
    
    reg           bayer_nset; // set color to bayer (start of frame up to first hact) when zero
    wire          sync_bayer; // at the beginning of the line - sync color to bayer
    reg     [1:0] color; // for selecting page in a gamma table
    reg           bayer0_latched; // latch bayer[0] at the beginning of first line
//    reg           hact_m;
    reg     [4:0] hact_d; // combine several delays?
//    reg           en_d;
    reg     [7:0] cdata;   //8-bit pixel data after "curves"
// modified table data to increase precision. table_base[9:0] is now 10 bits (2 extra).
// The 10-bit interpolation will be rounded to 8 bits at the very last stage
// 8 bit table_diff will be "floating point" with the following format
// now "signed" is 2's complement, was sign, abs() before

    reg     [7:0] table_diff_m; // 8 msbs in table word - msb - sign (0 plus, 1 - minus), other 7 bits - +/-127 difference to the next value
    reg     [9:0] table_base_m; // 10 lsbs in the table - base value, will be corrected using table_diff and input data lsbs (2 for now)
    wire   [35:0] table_mult;
    
// register decoded memory output
    reg     [9:0] table_base;
    reg    [10:0] table_diff;
    reg    [17:7] table_mult_r;
    reg    [ 9:0] table_base_r;
    
    wire    [9:0] interp_data;
    wire    [7:0] pxd_in_d3;
    reg     [7:0] pxd_in_r4; // register to be absorbed in mpy
    
    reg           vblank;    // from sof to first hact
    reg           pend_trig; // pending trigger (if trig came outside of vblank 
    wire          sof_masked;
    reg           frame_run;
    wire          trig_soft;
    wire          trig;
    wire   [10:0] table_raddr;
    wire   [17:0] table_rdata0;
    wire   [17:0] table_rdata1;
    wire   [17:0] table_rdata2;
    wire   [17:0] table_rdata3;
    wire   [17:0] table_rdata;

    assign        pxd_out = cdata;
    assign        hact_out = hact_d[4];
    
    assign set_ctrl_w =   cmd_we && (cmd_a == SENS_GAMMA_CTRL );
//    assign set_status_w = cmd_we && (cmd_a == SENS_GAMMA_STATUS );
//    assign set_taddr_w =  cmd_we && (cmd_a == SENS_GAMMA_TADDR );
//    assign set_tdata_w =  cmd_we && (cmd_a == SENS_GAMMA_TDATA );
    assign set_taddr_w =  cmd_we && (cmd_a == SENS_GAMMA_ADDR_DATA ) && cmd_data[20];
    assign set_tdata_w =  cmd_we && (cmd_a == SENS_GAMMA_ADDR_DATA ) && !cmd_data[20];
    
    assign set_height01_w =  cmd_we && (cmd_a == SENS_GAMMA_HEIGHT01 );
    assign set_height2_w =  cmd_we && (cmd_a == SENS_GAMMA_HEIGHT2 );
    
    assign ram_chn= SENS_GAMMA_BUFFER ? sensor_subchn: {1'b0, sensor_subchn[1]};
    assign table_re= {4{hact_in}} & { ram_chn[1] &  ram_chn[0],
                                      ram_chn[1] & ~ram_chn[0],
                                     ~ram_chn[1] &  ram_chn[0],
                                     ~ram_chn[1] & ~ram_chn[0]};
    assign table_raddr= SENS_GAMMA_BUFFER ?
                             {table_page,color[1:0],pxd_in[15:8]}:
                             {ram_chn[0],color[1:0],pxd_in[15:8]};

// TODO: register data    
    assign table_rdata= ram_chn_d2[1]?
                            (ram_chn_d2[0]?table_rdata3:table_rdata2):
                            (ram_chn_d2[0]?table_rdata1:table_rdata0);
//    assign {table_diff_w[7:0],table_base_w[9:0]} = table_rdata;

    assign bayer =        mode[SENS_GAMMA_MODE_BAYER +: 2];
    assign table_page =   mode[SENS_GAMMA_MODE_PAGE]; // TODO: re-assign?
    assign en_input =     mode[SENS_GAMMA_MODE_EN]; 
    assign repet_mode =   mode[SENS_GAMMA_MODE_REPET]; // TODO: re-assign?
    
    assign sync_bayer=hact_d[1] && ~hact_d[2];
    assign interp_data[9:0] = table_base_r[9:0]+table_mult_r[17:8]+table_mult_r[7]; //round
    assign table_mult=table_diff*{1'b0,pxd_in_r4[7:0]}; // 11 bits, signed* 9 bits, positive
    
    assign sof_masked= sof_in && (pend_trig || repet_mode) && en_input;
    assign trig = trig_in || trig_soft;
    always @ (posedge rst or posedge mclk) begin
        if      (rst)         tdata <= 0;
        else if (set_taddr_w) tdata <= cmd_data[17:0];
    
        if (rst) set_tdata_r <= 0;
        else     set_tdata_r <= set_tdata_w;
        
        if      (rst)         taddr <= 0;
        else if (set_taddr_w) taddr <= cmd_data[12:0];
        else if (set_tdata_r) taddr <= taddr + 1;
        
        if      (rst)         mode_mclk <= 0;
        else if (set_ctrl_w)  mode_mclk <= cmd_data[SENS_GAMMA_MODE_WIDTH-1:0];
        
        if (rst) set_tdata_ram <=0;
        else     set_tdata_ram <= {4{set_tdata_w}} &
                                  { taddr[12] &  taddr[11],
                                    taddr[12] & ~taddr[11],
                                   ~taddr[12] &  taddr[11],
                                   ~taddr[12] & ~taddr[11]};
        if      (rst)            height0_m1 <= 0;
        else if (set_height01_w) height0_m1 <= cmd_data[15:0];
                                   
        if      (rst)            height1_m1 <= 0;
        else if (set_height01_w) height1_m1 <= cmd_data[31:16];
                                   
        if      (rst)            height2_m1 <= 0;
        else if (set_height2_w)  height2_m1 <= cmd_data[15:0];
                                   
                                   
    end 

    always @ (posedge rst or posedge pclk) begin
        if (rst) begin
            mode <= 0;
            hact_d[4:0] <= 0;
            bayer_nset <= 0;
            bayer0_latched <= 0;
            color[1:0] <= 0;
            cdata[7:0] <= 0;
            vblank     <= 0;  // from sof to first hact
            pend_trig  <= 0; // pending trigger (if trig came outside of vblank
            frame_run <= 0; 
            
        end else begin
            mode <= mode_mclk;
            hact_d[4:0] <= {hact_d[3:0],hact_in};
            bayer_nset <= frame_run && (bayer_nset || hact_in);
            bayer0_latched <= bayer_nset? bayer0_latched:bayer[0];
            color[1:0] <= { bayer_nset? (sync_bayer ^ color[1]):bayer[1] ,
                           (bayer_nset &&(~sync_bayer))?~color[0]:bayer0_latched };
            pxd_in_r4 <= pxd_in_d3;
            cdata[7:0] <= interp_data[9:2];
            vblank <= sof_in || (vblank && !hact_in);
            pend_trig <= (trig && !vblank) || (pend_trig && !sof_in);  
            frame_run <= sof_masked || (frame_run && !eof_in);
        end
        
        
    end
    
  always @ (posedge pclk) begin
    {table_diff_m[7:0],table_base_m[9:0]} <= table_rdata;
    table_base[9:0]  <= table_base_m[9:0];
    table_diff[10:0] <= table_diff_m[7]?
                          {table_diff_m[6:0],4'b0}:
                          {{4{table_diff_m[6]}},table_diff_m[6:0]}; 
    table_mult_r[17:7] <= table_mult[17:7];
    table_base_r[ 9:0] <= table_base[ 9:0];
    
    table_regen <= table_re;
    ram_chn_d   <= ram_chn;
    ram_chn_d2  <= ram_chn_d;
    
    inc_line <= hact_d[0] && !hact_in && (sensor_subchn < SENS_GAMMA_NUM_CHN);
    
    sof_r <= sof_in;
    
    if      (sof_r)                        sensor_subchn <= 0;
    else if (inc_line && (line_cntr == 0)) sensor_subchn <= sensor_subchn+1;
    
    if      (sof_r)                        line_cntr <= height0_m1;
    else if (inc_line && (line_cntr == 0)) line_cntr <= (sensor_subchn ==0)? height1_m1: height2_m1;
    
  end
    
    
    cmd_deser #(
        .ADDR        (SENS_GAMMA_ADDR),
        .ADDR_MASK   (SENS_GAMMA_ADDR_MASK),
        .NUM_CYCLES  (6),
        .ADDR_WIDTH  (2),
        .DATA_WIDTH  (32)
    ) cmd_deser_sens_io_i (
        .rst         (rst), // input
        .clk         (mclk), // input
        .ad          (cmd_ad), // input[7:0] 
        .stb         (cmd_stb), // input
        .addr        (cmd_a), // output[15:0] 
        .data        (cmd_data), // output[31:0] 
        .we          (cmd_we) // output
    );

    dly_16 #(
        .WIDTH(8)
    ) dly_16_pxd_i (
        .clk (pclk),        // input
        .rst (rst),         // input
        .dly (3),           // input[3:0] 
        .din (pxd_in[7:0]), // input[0:0] 
        .dout(pxd_in_d3)    // output[0:0] 
    );

    dly_16 #(
        .WIDTH(2)
    ) dly_16_sof_eof_i (
        .clk (pclk),        // input
        .rst (rst),         // input
        .dly (4),           // input[3:0] 
        .din ({eof_in, sof_masked}), // input[0:0] 
        .dout({eof_out,sof_out})    // output[0:0] 
    );
    pulse_cross_clock trig_soft_i (
        .rst       (rst),
        .src_clk   (mclk),
        .dst_clk   (pclk),
        .in_pulse  (cmd_data[SENS_GAMMA_MODE_TRIG] && set_ctrl_w),
        .out_pulse (trig_soft),
        .busy      ());

    // channel0 (or 0,1 - always present)
    ramp_var_w_var_r #(
        .REGISTERS    (1), // try to delay i2c_byte_start by one more cycle
        .LOG2WIDTH_WR (4),
        .LOG2WIDTH_RD (4),
        .DUMMY        (0)
    ) gamma_table0_i (
        .rclk         (pclk), // input
        .raddr        (table_raddr), // input[11:0] 
        .ren          (table_re[0]), // input TODO: add "en"?
        .regen        (table_regen[0]), // input
        .data_out     (table_rdata0), // output[7:0] 
        .wclk         (mclk), // input
        .waddr        (taddr[10:0]), // input[9:0] 
        .we           (set_tdata_ram[0]), // input
        .web          (8'hff), // input[7:0] 
        .data_in      (tdata) // input[31:0] 
    );
    // Optionally generated/ replaced by dummy
    ramp_var_w_var_r #(
        .REGISTERS    (1), // try to delay i2c_byte_start by one more cycle
        .LOG2WIDTH_WR (4),
        .LOG2WIDTH_RD (4),
        .DUMMY        (!((SENS_GAMMA_NUM_CHN > 1) && ((SENS_GAMMA_NUM_CHN > 2) || SENS_GAMMA_BUFFER)))
    ) gamma_table1_i (
        .rclk         (pclk), // input
        .raddr        (table_raddr), // input[11:0] 
        .ren          (table_re[1]), // input TODO: add "en"?
        .regen        (table_regen[1]), // input
        .data_out     (table_rdata1), // output[7:0] 
        .wclk         (mclk), // input
        .waddr        (taddr[10:0]), // input[9:0] 
        .we           (set_tdata_ram[1]), // input
        .web          (8'hff), // input[7:0] 
        .data_in      (tdata) // input[31:0] 
    );

    ramp_var_w_var_r #(
        .REGISTERS    (1), // try to delay i2c_byte_start by one more cycle
        .LOG2WIDTH_WR (4),
        .LOG2WIDTH_RD (4),
        .DUMMY        (!(SENS_GAMMA_BUFFER && (SENS_GAMMA_NUM_CHN > 2)))
    ) gamma_table2_i (
        .rclk         (pclk), // input
        .raddr        (table_raddr), // input[11:0] 
        .ren          (table_re[2]), // input TODO: add "en"?
        .regen        (table_regen[2]), // input
        .data_out     (table_rdata2), // output[7:0] 
        .wclk         (mclk), // input
        .waddr        (taddr[10:0]), // input[9:0] 
        .we           (set_tdata_ram[2]), // input
        .web          (8'hff), // input[7:0] 
        .data_in      (tdata) // input[31:0] 
    );

    ramp_var_w_var_r #(
        .REGISTERS    (1), // try to delay i2c_byte_start by one more cycle
        .LOG2WIDTH_WR (4),
        .LOG2WIDTH_RD (4),
        .DUMMY        (!(SENS_GAMMA_BUFFER && (SENS_GAMMA_NUM_CHN > 3)))
    ) gamma_table3_i (
        .rclk         (pclk), // input
        .raddr        (table_raddr), // input[11:0] 
        .ren          (table_re[3]), // input TODO: add "en"?
        .regen        (table_regen[3]), // input
        .data_out     (table_rdata3), // output[7:0] 
        .wclk         (mclk), // input
        .waddr        (taddr[10:0]), // input[9:0] 
        .we           (set_tdata_ram[3]), // input
        .web          (8'hff), // input[7:0] 
        .data_in      (tdata) // input[31:0] 
    );

endmodule

