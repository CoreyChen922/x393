/*
** -----------------------------------------------------------------------------**
** huffman_snglclk.v
**
** Huffman encoder for JPEG compressor
**
** Copyright (C) 2002-20015 Elphel, Inc
**
** -----------------------------------------------------------------------------**
**  huffman_snglclk is free software - hardware description language (HDL) code.
** 
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
** -----------------------------------------------------------------------------**
**
*/
`include "system_defines.vh" 
// 01/22/2004 - extended flush until ready (modified stuffer.v too)
module huffman_snglclk    (
    input             xclk,            // pixel clock, sync to incoming data
    input             rst,             // @xclk
// Interface to program Huffman tables
    input             mclk,            // system clock to write tables
    input             tser_we,         // enable write to a  table
    input             tser_a_not_d,    // address/not data distributed to submodules
    input      [ 7:0] tser_d,          // byte-wide serialized tables address/data to submodules
    
// Input data     
    input      [15:0] di,              // [15:0]    specially RLL prepared 16-bit data (to FIFO) (sync to xclk)
    input             ds,              // di valid strobe  (sync to xclk)
// Output data    
    output     [26:0] do27,            // [26:0]    output data, MSB aligned
    output     [ 4:0] dl,              // [4:0] data length 
    output            dv,              // output data valid
    
    output            flush,           // last block done - flush the rest bits
    output            last_block,
    output reg        test_lbw,
    output            gotLastBlock,   // last block done - flush the rest bits
    input             clk_flush,      // other clock to generate synchronized 1-cycle flush_clk output   
    output            flush_clk,       // 1-cycle flush output @ clk_flush
    output            fifo_or_full     // FIFO output register full - just for debuging
);

// A small input FIFO, only needed for RLL >16 that require several clock cycles to output

    reg         fifo_re;
    wire        fifo_rdy;
    wire [15:0] fifo_out;
    fifo_same_clock #(
        .DATA_WIDTH(16),
        .DATA_DEPTH(4)
    ) fifo_same_clock_i (
        .rst       (1'b0), // input
        .clk       (xclk), // input
        .sync_rst  (rst), // input
        .we        (ds), // input
        .re        (fifo_re), // input
        .data_in   (di), // input[15:0] 
        .data_out  (fifo_out), // output[15:0] 
        .nempty    (fifo_rdy), // output
        .half_full () // output reg 
    );
    assign fifo_or_full = fifo_rdy;
    wire gotDC=           fifo_out[15] &&  fifo_out[14];
    wire gotAC=           fifo_out[15] && !fifo_out[14];
    wire gotRLL=         !fifo_out[15] && !fifo_out[12];
    wire gotEOB=         !fifo_out[15] &&  fifo_out[12];
    assign gotLastBlock=  fifo_out[15] &&  fifo_out[14] && fifo_out[12] && fifo_re;
    wire gotLastWord=    !fifo_out[14] &&  fifo_out[12] && fifo_re;    // (AC or RLL) and last bit set
    wire gotColor=        fifo_out[13];
    reg     [5:0] rll;    // 2 MSBs - counter to send "f0" codes
    reg     [3:0] rll1;   // valid at cycle "1"
    reg     [3:0] rll2;   // valid at cycle "1"
    reg     [2:0] gotAC_r;
    reg     [2:0] gotDC_r;
    reg     [2:0] gotEOB_r;
    reg     [2:0] gotColor_r;
    reg     [2:1] gotF0_r;    
    
    reg    [11:0] sval;    // signed input value
    wire    [3:0] val_length;
    wire   [10:0] val_literal;
    reg     [8:0] htable_addr;     // address to huffman table
    reg     [2:0] htable_re;       // Huffman table memory re, regen, out valid
    wire   [31:0] htable_out;      // Only [19:0] are used
    wire    [3:0] val_length_late; // delay by 3 clocks to match Huffman table output
    wire   [10:0] val_literal_late;// delay by 3 clocks to match Huffman table output

    reg           ready_to_flush;
    
    reg            flush_r;           // last block done - flush the rest bits
    reg            last_block_r;
    reg     [9:0]  active_r;
    wire           active = fifo_re || active_r[0];
    
    assign flush =        flush_r;
    assign last_block =   last_block_r;
    assign fifo_or_full = fifo_rdy;
    
    always @(posedge xclk) begin
        if (rst) fifo_re <= 0;
        else     fifo_re <= fifo_rdy && !(fifo_re && gotRLL) && !(|rll[5:4]);
    
        if (rst) gotAC_r <= 0;
        else     gotAC_r <= {gotAC_r[1:0], gotAC && fifo_re};
    
        if (rst) gotDC_r <= 0;
        else     gotDC_r <= {gotDC_r[1:0], gotDC && fifo_re};

        if (rst) gotEOB_r <= 0;
        else     gotEOB_r <= {gotEOB_r[1:0], gotEOB && fifo_re};

        if (rst) gotColor_r <= 0;
        else     gotColor_r <= {gotColor_r[1:0], (gotDC && fifo_re) ? gotColor : gotColor_r[0] };

        if      (rst)               rll[5:4] <= 0;
        else if (fifo_re && gotRLL) rll[5:4] <= fifo_out[5:4];
        else if (gotAC_r[0])        rll[5:4] <= 0; // combine with !en?
        else if (|rll[5:4])         rll[5:4] <=rll[5:4] - 1;
        
        if      (rst)               rll[3:0] <= 0;
        else if (fifo_re)           rll[3:0] <= gotRLL ? fifo_out[3:0] : 4'b0;
        
        rll1 <= rll[3:0];
        rll2 <= rll1;
        
        if (rst) gotF0_r[2:1] <= 0;
        else     gotF0_r[2:1] <= {gotF0_r[1], (|rll[5:4])};
        
//        if (fifo_re) sval[11:0] <= fifo_out[11:0];
        sval[11:0] <= fifo_out[11:0];
        
        htable_addr[8] <= gotColor_r[2];  // switch Huffman tables
        htable_addr[7:0] <= ({8{gotEOB_r[2]}} & 8'h0 )   | // generate 00 code (end of block)
                      ({8{gotF0_r[2]}}  & 8'hf0 )  | // generate f0 code (16 zeros)
                      ({8{gotDC_r[2]}}  & {val_length[3:0], 4'hf}) |
                      ({8{gotAC_r[2]}}  & {rll2[3:0],       val_length[3:0]});
       
       if (rst)  htable_re <= 0;
       else      htable_re <= {htable_re[1:0], gotEOB_r[2] | gotF0_r[2] | gotDC_r[2] | gotAC_r[2]};

       // other signals
       
       if    (rst || flush_r)                 last_block_r <= 0;
       else if (gotLastBlock)                 last_block_r <= 1;
       
       if      (rst || flush_r)               ready_to_flush <= 0;
       else if (last_block_r &&  gotLastWord) ready_to_flush <= 1;

       test_lbw <= last_block &&  gotLastWord;
       
        if      (rst)     active_r <= 0;
        else if (fifo_re) active_r <= 10'h3ff;
        else              active_r <= active_r >> 1;
        
        if (rst) flush_r <= 0;
        else     flush_r <= ready_to_flush && !active;
        
    end

    varlen_encode_snglclk varlen_encode_snglclk_i (
        .clk     (xclk),       // input
        .d       (sval),       // input[11:0] 
        .l       (val_length), // output[3:0] reg 
        .q       (val_literal) // output[10:0] reg 
    );

    wire          twe;
    wire  [15:0]  tdi;
    wire  [22:0]  ta;
    
  
     table_ad_receive #(
        .MODE_16_BITS (1),
        .NUM_CHN      (1)
    ) table_ad_receive_i (
        .clk       (mclk),              // input
        .a_not_d   (tser_a_not_d),      // input
        .ser_d     (tser_d),            // input[7:0] 
        .dv        (tser_we),           // input
        .ta        (ta),                // output[22:0] 
        .td        (tdi),               // output[15:0] 
        .twe       (twe)                // output
    );

    ram18_var_w_var_r #(
        .REGISTERS(0),
        .LOG2WIDTH_WR(4),
        .LOG2WIDTH_RD(5),
        .DUMMY(0)
`ifdef PRELOAD_BRAMS
    `include "includes/huffman.dat.vh"
`endif
    ) i_htab (
        .rclk      (xclk),             // input
        .raddr     (htable_addr[8:0]), // input[8:0] 
        .ren       (htable_re[0]),     // input
        .regen     (htable_re[1]),     // input
        .data_out  (htable_out),       // output[31:0] 
        .wclk      (mclk),             // input
        .waddr     (ta[9:0]),          // input[9:0] 
        .we        (twe),              // input
        .web       (4'hf),             // input[3:0] 
        .data_in   (tdi[15:0])         // input[15:0] 
    );

    dly_16 #(
        .WIDTH(11)
    ) dly_16_val_literal_i (
        .clk      (xclk),              // input
        .rst      (rst),              // input
        .dly      (4'h2),             // input[3:0] 
        .din      (val_literal),      // input[0:0] 
        .dout     (val_literal_late)  // output[0:0] 
    );

    dly_16 #(
        .WIDTH(4)
    ) dly_16_val_length_i (
        .clk      (xclk),                                            // input
        .rst      (rst),                                             // input
        .dly      (4'h2),                                            // input[3:0] 
        .din      ((gotEOB_r[2] | gotF0_r[2]) ? 4'b0 :  val_length), // input[0:0] 
        .dout     (val_length_late)                                  // output[0:0] 
    );

    huffman_merge_code_literal huffman_merge_code_literal_i (
        .clk           (xclk),              // input
        .in_valid      (htable_re[2]),      // input
        .huff_code     (htable_out[15:0]),  // input[15:0] 
        .huff_code_len (htable_out[19:16]), // input[3:0] 
        .literal       (val_literal_late),  // input[10:0] 
        .literal_len   (val_length_late),   // input[3:0] 
        .out_valid     (dv),                // output reg 
        .out_bits      (do27),              // output[26:0] reg 
        .out_len       (dl)                 // output[4:0] reg 
    );

    pulse_cross_clock flush_clk_i (
        .rst       (rst),
        .src_clk   (xclk),
        .dst_clk   (clk_flush),
        .in_pulse  (flush),
        .out_pulse (flush_clk),
        .busy      ());

    
endmodule

