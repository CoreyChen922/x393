/*******************************************************************************
 * Module: membridge
 * Date:2015-04-26  
 * Author: andrey     
 * Description: bi-directional bridge between system and video memory over axi_hp
 *
 * Copyright (c) 2015 <set up in Preferences-Verilog/VHDL Editor-Templates> .
 * membridge.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  membridge.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
`timescale 1ns/1ps

module  membridge#(
    parameter MEMBRIDGE_ADDR=                     'h200,
    parameter MEMBRIDGE_MASK=                     'h3f0,
    parameter MEMBRIDGE_CTRL=                     'h0, // bit 0 - enable, bits[2:1]: 11 - start(continue), 01 - start and reset address
    parameter MEMBRIDGE_STATUS_CNTRL=             'h1,
    parameter MEMBRIDGE_LO_ADDR64=                'h2, // low address of the system memory, in 64-bit words (<<3 to get byte address)
    parameter MEMBRIDGE_SIZE64=                   'h3, // size of the system memory range (access will roll over to lo_addr
    parameter MEMBRIDGE_START64=                  'h4, // start address relative to lo_addr
    parameter MEMBRIDGE_LEN64=                    'h5, // full length of transfer in 64-bit words
    parameter MEMBRIDGE_WIDTH64=                  'h6, // frame width in 64-bit words (partial last page in each line)
    parameter MEMBRIDGE_STATUS_REG=               'h3b,
    parameter FRAME_HEIGHT_BITS=                   16,   // Maximal frame height bits
    parameter FRAME_WIDTH_BITS=                    13
//    ,parameter MCNTRL_SCANLINE_FRAME_PAGE_RESET=  1'b0 // reset internal page number to zero at the frame start (false - only when hard/soft reset)
    
)(
    input         rst,
    input         mclk, // for command/status
    input         hclk,   // global clock to run axi_hp @ 150MHz
    // programming interface
    input                   [7:0] cmd_ad,      // byte-serial command address/data (up to 6 bytes: AL-AH-D0-D1-D2-D3 
    input                         cmd_stb,     // strobe (with first byte) for the command a/d
    output                  [7:0] status_ad,   // status address/data - up to 5 bytes: A - {seq,status[1:0]} - status[2:9] - status[10:17] - status[18:25]
    output                        status_rq,   // input request to send status downstream
    input                         status_start, // Acknowledge of the first status packet byte (address)
    // mcntrl_linear_rw.v interface
    output                        frame_start_chn, // input
    output                        next_page_chn, // input
    input                         cmd_wrmem,      //
    input                         page_ready_chn, // output single mclk
    input                         frame_done_chn, // output single mclk
    input [FRAME_HEIGHT_BITS-1:0] line_unfinished_chn1, // output[15:0] @SuppressThisWarning VEditor unused (yet)
    output                        suspend_chn1, //
    // buffer interface, DDR3 memory read
    input                         xfer_reset_page_rd, // input
    input                         buf_wpage_nxt,     // input
    input                         buf_wr, // input
    input                  [63:0] buf_wdata,
    // buffer interface, DDR3 memory write
    input                         xfer_reset_page_wr, // input  @ posedge mclk
    input                         buf_rpage_nxt,
    input                         buf_rd,
    output                [63:0]  buf_rdata, 
    // axi_hp signals write channel
    // write address
    output  [31:0] afi_awaddr,
    output         afi_awvalid,
    input          afi_awready, // @SuppressThisWarning VEditor unused - used FIF0 level
    output  [ 5:0] afi_awid,
    output  [ 1:0] afi_awlock,
    output  [ 3:0] afi_awcache,
    output  [ 2:0] afi_awprot,
    output  [ 3:0] afi_awlen,
    output  [ 2:0] afi_awsize,
    output  [ 1:0] afi_awburst,
    output  [ 3:0] afi_awqos,
    // write data
    output  [63:0] afi_wdata,
    output         afi_wvalid,
    input          afi_wready,  // @SuppressThisWarning VEditor unused - used FIF0 level
    output  [ 5:0] afi_wid,
    output         afi_wlast,
    output  [ 7:0] afi_wstrb,
    // write response
    input          afi_bvalid,
    output         afi_bready,
    input   [ 5:0] afi_bid,      // @SuppressThisWarning VEditor unused
    input   [ 1:0] afi_bresp,    // @SuppressThisWarning VEditor unused
    // PL extra (non-AXI) signals
    input   [ 7:0] afi_wcount,
    input   [ 5:0] afi_wacount,
    output         afi_wrissuecap1en,
    // AXI_HP signals - read channel
    // read address
    output  [31:0] afi_araddr,
    output         afi_arvalid,
    input          afi_arready,  // @SuppressThisWarning VEditor unused - used FIF0 level
    output  [ 5:0] afi_arid,
    output  [ 1:0] afi_arlock,
    output  [ 3:0] afi_arcache,
    output  [ 2:0] afi_arprot,
    output  [ 3:0] afi_arlen,
    output  [ 2:0] afi_arsize,
    output  [ 1:0] afi_arburst,
    output  [ 3:0] afi_arqos,
    // read data
    input   [63:0] afi_rdata,
    input          afi_rvalid,
    output         afi_rready,
    input   [ 5:0] afi_rid,     // @SuppressThisWarning VEditor unused
    input          afi_rlast,   // @SuppressThisWarning VEditor unused
    input   [ 1:0] afi_rresp,   // @SuppressThisWarning VEditor unused
    // PL extra (non-AXI) signals
    input   [ 7:0] afi_rcount,
    input   [ 2:0] afi_racount,
    output         afi_rdissuecap1en
    
);
    // Some constant signals:
    
    assign afi_awlock =        2'h0;
    assign afi_awcache =       4'h3;
    assign afi_awprot =        3'h0;
    assign afi_awsize =        3'h3;
    assign afi_awburst =       2'h1;
    assign afi_awqos =         4'h0;
    assign afi_wstrb =         8'hff;
    assign afi_wrissuecap1en = 1'b0;

    assign afi_arlock =        2'h0;
    assign afi_arcache =       4'h3;
    assign afi_arprot =        3'h0;
    assign afi_arsize =        3'h3;
    assign afi_arburst =       2'h1;
    assign afi_arqos =         4'h0;
    assign afi_rdissuecap1en = 1'b0;


    assign frame_start_chn = start_mclk;
    assign suspend_chn1    = 1'b0;
    wire [ 3:0] cmd_a;    // control register address
    wire [31:0] cmd_data; // register data
    wire        cmd_we;   // register write
    
    wire set_ctrl_w;
    wire set_status_w;
    wire set_lo_addr64_w;
    wire set_size64_w;
    wire set_start64_w;
    wire set_len64_w;
    wire set_width64_w;
    
    
    assign set_ctrl_w =         cmd_we && (cmd_a== MEMBRIDGE_CTRL);
    assign set_lo_addr64_w =    cmd_we && (cmd_a== MEMBRIDGE_LO_ADDR64);
    assign set_size64_w =       cmd_we && (cmd_a== MEMBRIDGE_SIZE64);
    assign set_start64_w =      cmd_we && (cmd_a== MEMBRIDGE_START64);
    assign set_len64_w =        cmd_we && (cmd_a== MEMBRIDGE_LEN64);
    assign set_width64_w =      cmd_we && (cmd_a== MEMBRIDGE_WIDTH64);
    assign set_status_w =       cmd_we && (cmd_a== MEMBRIDGE_STATUS_CNTRL);
    reg [28:0] lo_addr64_mclk;
    reg [28:0] size64_mclk;
    reg [28:0] start64_mclk;
    reg [28:0] len64_mclk;
    reg [FRAME_WIDTH_BITS+1:0] width64_mclk; // FRAME_WIDTH_BITS in 128 bit bursts
    reg        rdwr_en_mclk;
    reg        rdwr_reset_addr_mclk; // resets system memory address
    reg        start_mclk;
//cmd_wrmem
    always @ (posedge mclk) begin
        if (set_lo_addr64_w)    lo_addr64_mclk       <= {cmd_data[28:4],4'b0}; // align to 16-bursts
        if (set_size64_w)       size64_mclk          <= {cmd_data[28:4],4'b0}; // align to 16-bursts
        if (set_lo_addr64_w)    start64_mclk         <= 0;
        else if (set_start64_w) start64_mclk         <= {cmd_data[28:4],4'b0}; // align to 16-bursts
        if (set_len64_w)        len64_mclk           <= cmd_data[28:0]; // OK not to be aligned
        if (set_width64_w)      width64_mclk         <= {~(|cmd_data[FRAME_WIDTH_BITS:0]),cmd_data[FRAME_WIDTH_BITS:0]}; // OK not to be aligned
        if (set_ctrl_w)         rdwr_reset_addr_mclk <= cmd_data[1] && !cmd_data[2];
        
    end

    always @ (posedge mclk or posedge rst) begin
        if      (rst)        rdwr_en_mclk <= 0;
        else if (set_ctrl_w) rdwr_en_mclk <= cmd_data[0];
        
        if   (rst) start_mclk <= 0;
        else       start_mclk <= set_ctrl_w & cmd_data[1];

    end
    
    // syncronize mclk ->hclk
    
    reg [28:0] lo_addr64;
    reg [28:0] size64;
    reg [28:0] start64;
    reg [28:0] len64;
    reg [FRAME_WIDTH_BITS:0]   last_in_line64;
    reg [24:0] last_addr1k; // last adress before rollover w/o 4 LSB
    reg        rdwr_en;     // TODO: Use it?
    reg        rdwr_reset_addr; // resets system memory address
    wire       start_hclk;
    reg        rd_start;
    reg        wr_start;
    reg  [2:0] rdwr_start;
    reg        wr_mode;
    wire       page_ready; // @ posedge hclk
    wire       frame_done; // @ posedge hclk
//next_page_chn
    wire       reset_page_wr; // @ posedge hclk (from @ posedge mclk)
    wire       reset_page_rd; // @ posedge hclk (from @ negedge mclk)
    reg        page_ready_rd;
    reg        page_ready_wr;
    reg        next_page_rd;
    reg        next_page_wr;
    
    wire       next_page; // @ posedge hclk - source 
    wire       busy_next_page; // do not send next_page -previous is crossing clock boundaries
    
    assign next_page= next_page_wr | next_page_rd;
    
    // incrementing IDs for read (MSB==0) and write (MSB==1)
    reg [4:0] rd_id;
    reg [4:0] wr_id;

    assign afi_arid={1'b1,rd_id};
    assign afi_awid={1'b1,wr_id};
    assign afi_wid= {1'b1,wr_id};

    
    
    
    always @ (posedge hclk) begin
        lo_addr64       <= lo_addr64_mclk;
        size64          <= size64_mclk;
        start64         <= start64_mclk;
        len64           <= len64_mclk;
//        width64         <= width64_mclk;
        last_in_line64  <= width64_mclk[FRAME_WIDTH_BITS:0]-1;
        wr_mode         <= cmd_wrmem;
        rdwr_reset_addr <= rdwr_reset_addr_mclk;
        last_addr1k     <= size64[28:4] - 1;
    end

    always @ (posedge hclk or posedge rst) begin
        if (rst) rdwr_en <= 0;
        else     rdwr_en <= rdwr_en_mclk;
        
        
        if (rst) rdwr_start <= 0;
        else     rdwr_start <= {rdwr_start[1:0],start_hclk};

        if (rst) rd_start <= 0;
        else     rd_start <= rdwr_start[2] && !wr_mode; // later to enable adders+ to propagate
        
        if (rst) wr_start <= 0;
        else     wr_start <= rdwr_start[2] && wr_mode;
        
        page_ready_rd <= page_ready && !wr_mode;
        
        if      (rst)      rd_id <= 0;
        else if (rd_start) rd_id <= rd_id +1;

        if      (rst)      wr_id <= 0;
        else if (wr_start) wr_id <= wr_id +1;

    end
    // mclk -> hclk
    pulse_cross_clock start_i          (.rst(rst), .src_clk(mclk), .dst_clk(hclk), .in_pulse(start_mclk), .out_pulse(start_hclk),.busy());
    pulse_cross_clock page_ready_i     (.rst(rst), .src_clk(mclk), .dst_clk(hclk), .in_pulse(page_ready_chn), .out_pulse(page_ready),.busy());
    pulse_cross_clock frame_done_i     (.rst(rst), .src_clk(mclk), .dst_clk(hclk), .in_pulse(frame_done_chn), .out_pulse(frame_done),.busy());
    pulse_cross_clock  reset_page_wr_i (.rst(rst), .src_clk(mclk), .dst_clk(hclk), .in_pulse(xfer_reset_page_wr), .out_pulse(reset_page_wr),.busy());
    // negedge mclk -> hclk (verify clock inversion is absorbed)
    pulse_cross_clock  reset_page_rd_i (.rst(rst), .src_clk(~mclk),.dst_clk(hclk), .in_pulse(xfer_reset_page_rd), .out_pulse(reset_page_rd),.busy());
    
    // hclk -> mclk
    pulse_cross_clock next_page_i  (.rst(rst), .src_clk(hclk), .dst_clk(mclk), .in_pulse(next_page), .out_pulse(next_page_chn),.busy(busy_next_page));
    
    // Common to both directions
    localparam DELAY_ADVANCE_ADDR=3;    
    reg [28:0] rel_addr64; // realtive (to lo_addr) address
    wire                         advance_rel_addr_w;
    wire                         advance_rel_addr_wr;
    wire                         advance_rel_addr_rd;
    
    reg                          advance_rel_addr;

    reg [DELAY_ADVANCE_ADDR-1:0] advance_rel_addr_d;
    reg                   [28:0] left64;
    reg                          last_burst;
    reg                          rollover;
    reg                   [ 3:0] afi_len;
    reg                   [ 4:0] afi_len_plus1;
    reg                          low4_zero;
    
    reg [28:0]                 buf_left64;      // number of 64-bit words yet to be read from the DDR3 (or written to it)
    reg [FRAME_WIDTH_BITS:0]   buf_in_line64;   // number of last 64-bit words in line
    
    //last_addr1k
    assign afi_awlen = afi_len;
    assign afi_arlen = afi_len;
    reg [28:0] axi_addr64;
    wire left_zero;
    
    assign afi_awaddr={axi_addr64,3'b0};
    assign afi_araddr={axi_addr64,3'b0};
    
    assign left_zero = low4_zero && last_burst;
    always @ (posedge hclk or posedge rst) begin
        if      (rst)                advance_rel_addr_d <= 0;
//        else if (advance_rel_addr_w) advance_rel_addr_d <= {DELAY_ADVANCE_ADDR{1'b1}};
        else                         advance_rel_addr_d <= {advance_rel_addr_d[DELAY_ADVANCE_ADDR-2:0],advance_rel_addr};
                
    end

    reg        read_started;
    reg        write_busy;
    wire       rw_in_progress;
    reg        busy;
    reg        done;

    assign rw_in_progress = read_started || write_busy;
    
    always @ (posedge hclk) begin
        advance_rel_addr <= advance_rel_addr_w && !advance_rel_addr && !(|advance_rel_addr_d); // make sure advance_rel_addr_w is recalculated after address change
        last_burst <= ! (|left64[28:4]);
        rollover <= rel_addr64[28:4] == last_addr1k;
        low4_zero <= ! (|left64[3:0]);
        if (rdwr_start[0] && rdwr_reset_addr) rel_addr64 <= start64;
        else if (advance_rel_addr) rel_addr64 <= last_burst?(rel_addr64 + {25'h0,left64[3:0]}) : (rollover?29'h0:(rel_addr64 + 29'h10));

        axi_addr64 <= lo_addr64 + rel_addr64;
        
        if (rdwr_start)            left64 <= len64;
        else if (advance_rel_addr) left64 <= last_burst? 0: (left64 - 29'h10);
        
        afi_len       <= (|left64[28:4])?4'hf : (left64[3:0]-1);
        afi_len_plus1 <= (|left64[28:4]) ? 5'h10 : {1'b0,left64[3:0]};
        
        page_ready_rd <= page_ready && !wr_mode;
        page_ready_wr <= page_ready &&  wr_mode;
        
        if (!rw_in_progress) buf_left64 <= len64;
        else if (buf_rdwr)   buf_left64 <= buf_left64 - 1;
        
        if (!rw_in_progress) buf_in_line64 <= 0;
        else if (buf_rdwr)   buf_in_line64 <= is_last_in_line? {(FRAME_WIDTH_BITS+1){1'b0}} : (buf_in_line64 +1);
        
        next_page_rd <= next_page_rd_w;
        next_page_wr <= next_page_wr_w;
        
        
        
    end

    // DDR3 read - AFI write
    //rdwr_en    
    reg  [7:0] axi_arw_requested;  // 64-bit words to be read/written over axi queued to AR/AW channels
    reg  [7:0] wresp_conf;         // number of 64-bit words confirmed through axi b channel
    wire [7:0] axi_wr_pending;     // Number of words qued to AW but not yet confirmed through B-channel;
    wire [7:0] axi_rd_pending;

    reg  [7:0] axi_rd_received;
    assign axi_rd_pending= axi_arw_requested - axi_rd_received;
    assign axi_wr_pending= axi_arw_requested - wresp_conf;
    
    reg        read_busy;
    reg        read_over;
    reg        afi_bvalid_r;
    reg  [1:0] read_page;
//    reg  [6:0] read_addr;
    reg  [2:0] read_pages_ready;
    
    assign afi_bready = 1'b1; // always ready to receive confirmation
    
    reg        afi_wd_safe_not_full;
    reg        afi_wa_safe_not_full;
    
    assign advance_rel_addr_w =  advance_rel_addr_wr || advance_rel_addr_rd;
    assign advance_rel_addr_wr = read_started && afi_wa_safe_not_full && (|left64); // left 64 is decremented by 16, except possibly the last (partial)
    
    assign afi_awvalid=advance_rel_addr && read_started;
    
    always @ (posedge hclk or posedge rst) begin
        if      (rst)       read_busy <= 0;
        else if (rd_start)  read_busy <= 1;
        else if (read_over) read_busy <= 0;
        if      (rst)        read_started <= 0;
        else if (!read_busy) read_started <= 0;
        else if (page_ready) read_started <= 1; // first page is in the buffer - use it to mask page number comparison

        afi_bvalid_r <=afi_bvalid;
        
        if      (rst)          wresp_conf <= 0;
        else if (!read_busy)   wresp_conf <= 0;
        else if (afi_bvalid_r) wresp_conf <= wresp_conf +1;
        
        read_over <= left_zero && (axi_wr_pending == 0) && read_started; 
        
        if      (rst)            read_page <= 0;
        else if (reset_page_rd)  read_page <= 0;
        else if (next_page_rd_w) read_page <= read_page + 1;

        if      (rst)                               read_pages_ready <= 0;
        else if (!read_busy)                        read_pages_ready <= 0;
        else if ( page_ready_rd && !next_page_rd_w) read_pages_ready <= read_pages_ready +1;
        else if (!page_ready_rd &&  next_page_rd_w) read_pages_ready <= read_pages_ready -1;
        
        if (rst) afi_wd_safe_not_full <= 0;
        else     afi_wd_safe_not_full <=  rdwr_en && (!afi_wcount[7] && !(&afi_wcount[6:3]));

        if (rst) afi_wa_safe_not_full <= 0;
        else     afi_wa_safe_not_full <=  rdwr_en && (!afi_wacount[5] && !(&afi_wacount[4:2]));
        
        if (rst) busy <= 0;
        else     busy <=  read_busy || write_busy;
        
        if      (rst)                                                    done <= 0;
        else if (!rdwr_en)                                               done <= 0; // disabling when idle will reset done
        else if ((write_busy && frame_done) || (read_busy && read_over)) done <= 1;
        else if (rdwr_start)                                             done <= 0;
        
    end
    
    // handle interaction with the buffer, advance addresses, keep track of partial (last) pages in each line
    wire                       bufrd_rd_w;
    wire                       bufwr_we_w; // TODO: assign
    
    reg                  [2:0] bufrd_rd;
    reg                  [1:0] bufwr_we;
    reg                        buf_rdwr; // equiv to  bufrd_rd[0] || bufwr_we)
    wire                       is_last_in_line;
    wire                       is_last_in_page;
    wire                       next_page_rd_w;
    wire                       next_page_wr_w;
    assign next_page_rd_w = read_started && !busy_next_page && is_last_in_page && bufrd_rd[0];
    assign is_last_in_line = buf_in_line64 == last_in_line64;
    assign is_last_in_page = is_last_in_line || (&buf_in_line64[6:0]);
    assign bufrd_rd_w = afi_wd_safe_not_full && (|read_pages_ready[2:1] || (read_pages_ready[0] && !is_last_in_page));
//last_in_line64 - last word number in scan line
    reg                        left_was_1; // was 1 or 0 (0 does not matter)
    reg                  [3:0] src_wcntr;
    reg                  [2:0] wlast_in_burst;
    
    assign afi_wlast = wlast_in_burst[2];
     
    always @ (posedge hclk) begin
        if (!rw_in_progress) left_was_1 <= 0;
        else if   (buf_rdwr) left_was_1 <= !(|buf_left64[28:1]);
        
        if    (!read_started) src_wcntr <= 0;
        else if (bufrd_rd[0]) src_wcntr <= src_wcntr+1;
        
        if    (!read_started) wlast_in_burst <= 0;
        else if (bufrd_rd[0]) wlast_in_burst <= {wlast_in_burst[1:0],left_was_1 | (&src_wcntr)};
        
        bufrd_rd <= {bufrd_rd[1:0], bufrd_rd_w };
        buf_rdwr <= bufrd_rd_w || bufwr_we_w;
        bufwr_we <= {bufwr_we[0],bufwr_we_w};
        
    end
    assign afi_wvalid=bufrd_rd[2];

    // write to ddr3 from afi
    reg        afi_rd_safe_not_empty;
    reg        afi_ra_safe_not_full;
    reg        afi_safe_rd_pending;
 //    assign advance_rel_addr_wr = read_started && afi_wa_safe_not_full && (|left64); // left 64 is decremented by 16, except possibly the last (partial)
    assign advance_rel_addr_rd = write_busy && afi_ra_safe_not_full && afi_safe_rd_pending && (|left64);
    assign afi_arvalid=advance_rel_addr && write_busy;

    assign next_page_wr_w = write_busy && !busy_next_page && is_last_in_page && bufwr_we[0];
    
    assign bufwr_we_w= afi_rd_safe_not_empty && !write_pages_ready[2] && (!(&write_pages_ready[1:0]) ||  !is_last_in_page);
    
    // handle buffer address, page 
    reg  [1:0] write_page;        // current number of buffer page
    reg  [2:0] write_pages_ready; // number of pages in the buffer
    reg  [1:0] write_page_r;      // 1-cycle delayed page address
    reg  [6:0] buf_in_line64_r;   // 1-cycle delayed buffer address
    
    assign afi_rready = bufwr_we[0];

    always @ (posedge hclk or posedge rst) begin
        if      (rst)        write_busy <= 0;
        else if (wr_start)   write_busy <= 1;
        else if (frame_done) write_busy <= 0;

        if      (rst)                           axi_arw_requested <= 0;
        else if (!write_busy && !read_started)  axi_arw_requested <= 0;
        else if (advance_rel_addr)              axi_arw_requested <= axi_arw_requested + afi_len_plus1;

        if      (rst)              axi_rd_received <= 0;
        else if (!write_busy)      axi_rd_received <= 0;
        else if (bufwr_we[0])      axi_rd_received <= axi_rd_received + 1;
        
        
        if (rst) afi_rd_safe_not_empty <= 0;
         // allow 1 cycle latency, no continuous reads when FIFO is low (like in the very end of the transfer)
         // Adjust '2' in afi_rcount[6:2] ? 
        else     afi_rd_safe_not_empty <= rdwr_en && ( afi_rcount[7] || (|afi_rcount[6:2]) || (!(|bufwr_we) && afi_rvalid));

        if (rst) afi_ra_safe_not_full <= 0;
        else     afi_ra_safe_not_full <= rdwr_en && ( !afi_racount[2] && !(&afi_racount[1:0]));
        
        if       (rst)        afi_safe_rd_pending <= 0;
        else if (!write_busy) afi_safe_rd_pending <= 0;
        else                  afi_safe_rd_pending <= rdwr_en && ( !axi_rd_pending[7] && !(&axi_rd_pending[6:4]));
        
        // handle buffer address, page 
        if      (rst)            write_page <= 0;
        else if (reset_page_wr)  write_page <= 0;
        else if (next_page_wr_w) write_page <= write_page + 1;

        if      (rst)                               write_pages_ready <= 0;
        else if (!write_busy)                       write_pages_ready <= 0;
        else if ( page_ready_wr && !next_page_wr_w) write_pages_ready <= write_pages_ready -1; //+1;
        else if (!page_ready_wr &&  next_page_wr_w) write_pages_ready <= write_pages_ready +1; //-1;

    end
        
    always @ (posedge hclk) begin
        write_page_r    <= write_page;
        buf_in_line64_r <= buf_in_line64[6:0];
    end    
        
    cmd_deser #(
        .ADDR       (MEMBRIDGE_ADDR),
        .ADDR_MASK  (MEMBRIDGE_MASK),
        .NUM_CYCLES (6),
        .ADDR_WIDTH (4),
        .DATA_WIDTH (32)
    ) cmd_deser_32bit_i (
        .rst        (rst), // input
        .clk        (mclk), // input
        .ad         (cmd_ad), // input[7:0] 
        .stb        (cmd_stb), // input
        .addr       (cmd_a), // output[3:0] 
        .data       (cmd_data), // output[31:0] 
        .we         (cmd_we) // output
    );

    status_generate #(
        .STATUS_REG_ADDR  (MEMBRIDGE_STATUS_REG),
        .PAYLOAD_BITS     (2) // ???
    ) status_generate_i (
        .rst              (rst), // input
        .clk              (mclk), // input
        .we               (set_status_w), // input
        .wd               (cmd_data[7:0]), // input[7:0] 
        .status           ({done,busy}), // input[25:0] 
        .ad               (status_ad), // output[7:0] 
        .rq               (status_rq), // output
        .start            (status_start) // input
    );

// Port 1rd (read DDR to AFI) buffer, linear
    mcntrl_buf_rd #(
        .LOG2WIDTH_RD(6) // 64 bit external interface
    ) chn1rd_buf_i (
        .ext_clk      (hclk), // input
        .ext_raddr    ({read_page,buf_in_line64[6:0]}), // input[8:0] 
        .ext_rd       (bufrd_rd[0]), // input
        .ext_regen    (bufrd_rd[1]), // input
        .ext_data_out (afi_wdata), // output[63:0] 
        .wclk         (!mclk), // input
        .wpage_in     (2'b0), // input[1:0] 
        .wpage_set    (xfer_reset_page_rd), // input  TODO: Generate @ negedge mclk on frame start
        .page_next    (buf_wpage_nxt), // input
        .page         (), // output[1:0]
        .we           (buf_wr), // input
        .data_in      (buf_wdata) // input[63:0] 
    );

// Port 1wr (write DDR from AFI) buffer, linear
    mcntrl_buf_wr #(
         .LOG2WIDTH_WR(6)  // 64 bit external interface
    ) chn1wr_buf_i (
        .ext_clk      (hclk), // input
        .ext_waddr    ({write_page_r, buf_in_line64_r[6:0]}), // input[8:0] 
        .ext_we       (bufwr_we[1]), // input
        .ext_data_in  (afi_rdata), // input[63:0] buf_wdata - from AXI
        .rclk         (mclk), // input
        .rpage_in     (2'b0), // input[1:0] 
        .rpage_set    (xfer_reset_page_wr), // input  @ posedge mclk
        .page_next    (buf_rpage_nxt), // input
        .page         (), // output[1:0]
        .rd           (buf_rd), // input
        .data_out     (buf_rdata) // output[63:0] 
    );

endmodule

