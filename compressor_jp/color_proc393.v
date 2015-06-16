/*******************************************************************************
 * Module: color_proc393
 * Date:2015-06-10  
 * Author: andrey     
 * Description: Color processor for JPEG 4:2:0/JP4
 * Updating from the earlier 2002-2010 version
 *
 * Copyright (c) 2002-2015 <set up in Preferences-Verilog/VHDL Editor-Templates> .
 * color_proc393.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  color_proc393.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
`timescale 1ns/1ps

`define DEBUG_COMPRESSOR
module  color_proc393 (
         input          clk,            // pixel clock (1/2 system clock - 80MHz)
         input          en,         // Enable (0 will reset states)
         input          en_sdc,     // enable subtracting of DC component
         input          go,         // pulse to star/restart (needed for each frame, repeat generated by the caller)
         // TODO: Remove
         input   [25:0] nblocks,    // ***** was [17:0] number of 16x16 blocks to read (valid @ "go" pulse)
         // NEW: Now number of SDRAM blobks (tiles) is not equal to number of macroblocks
         input   [12:0] n_blocks_in_row,   // number of macroblocks in a macroblock row
         input   [12:0] n_block_rows,      // number of macroblock rows in a frame
//         input          reset_sdram_page,  // SDRAM buffer page may be reset (normally just increments for each new tile
         // end of NEW
         output         eot,            // single-cycle end of transfer pulse
         input   [ 9:0] m_cb,       // [9:0] scale for CB - default 0.564 (10'h90)
         input   [ 9:0] m_cr,       // [9:0] scale for CB - default 0.713 (10'hb6)
         input          memWasInit, // memory channel2 was just initialized - reset page address (at posedge clk)
         input   [ 7:0] di,         // [7:0]
         output  [11:0] sdram_a,    // ***** was [10:0]    (MSB - SDRAM buffer page number)
         input          sdram_rdy,  // SDRAM buffer ready
         output         sdram_next, // request to read a page to SDRAM buffer
         output         inc_sdrama, // enable read sdram buffer
         output         inc_sdrama_d,// ***** NEW regen sdram buffer (delay by 1 clock
         input          noMoreData,   // used as alternative to end frame input (possibly broken frame)

         output         dv_raw,     // data valid for di (for testing to bypass color conversion - use di[7:0])
         input          ignore_color,   //zero Cb/Cr components
         input          four_blocks, // use only 4 blocks for the output, not 6
         input          jp4_dc_improved, // in JP4 mode, compare DC coefficients to the same color ones
         input   [ 1:0] tile_margin, // margins around 16x16 tiles (0/1/2)
         input   [ 2:0] tile_shift, // tile shift from top left corner
         input   [ 2:0] converter_type, // 0 - color18, 1 - color20, 2 - mono, 3 - jp4, 4 - jp4-diff
         input          scale_diff,     // divide differences by 2 (to fit in 8-bit range)
         input          hdr,            // second green absolute, not difference
         output  [ 9:0] do,         // [9:0] data out (4:2:0) (signed, average=0)
         output  [ 8:0] avr,        // [8:0]    DC (average value) - RAM output, no register. For Y components 9'h080..9'h07f, for C - 9'h100..9'h0ff!
         output         dv,         // out data valid (will go high for at least 64 cycles)
         output         ds,         // single-cycle mark of the first_r pixel in a 64 (8x8) - pixel block
         output  [ 2:0] tn,         // [2:0] tile number 0..3 - Y, 4 - Cb, 5 - Cr (valid with start)
         output         first,      // sending first_r MCU (valid @ ds)
         output         last,       // sending last_r MCU (valid @ ds)
         output  [ 7:0] n000,       // [7:0] number of zero pixels (255 if 256)
         output  [ 7:0] n255,       // [7:0] number of 0xff pixels (255 if 256)
         input   [ 1:0] bayer_phase, //[1:0])  bayer color filter phase 0:(GR/BG), 1:(RG/GB), 2: (BG/GR), 3: (GB/RG)
// below signals valid at ds ( 1 later than tn, first_r, last_r)
         output   [2:0] component_num,    //[2:0] - component number (YCbCr: 0 - Y, 1 - Cb, 2 - Cr, JP4: 0-1-2-3 in sequence (depends on shift) 4 - don't use
         output         component_color,  // use color quantization table (YCbCR, jp4diff)
         output         component_first,   // first_r this component in a frame (DC absolute, otherwise - difference to previous)
         output         component_lastinmb // last_r component in a macroblock;
`ifdef DEBUG_COMPRESSOR
        ,output         bcntrIsZero
        ,output [25:0]  bcntr
`endif
                     );

  wire  [8:0]   y_out; // data from buffer
  wire  [8:0]   c_out; // data from buffer

  reg       [1:0]   wpage; // page (0/1) where data is being written to (both Y and CbCr)
  reg       [1:0]   rpage; // page (0/1) from where data is sent out ( both Y and CbCr)
  reg             sdram_next_r;
  reg      [25:0] bcntr_r; // down counter of blocks left
  reg             bcntrIsZero_r; // one cycle of bcntr_r[]==0
  reg             eot_r;
  reg             ccv_start_en;   //
  reg             ccv_out_start,ccv_out_start_d;  // start output of YCbCr from buffers
  reg     [8:0]   raddr;          // output address of buffer memories (MSB selects Y(0)/CbCr(1))
  reg             raddr8_d;       // raddr[8] delayed by 1 clock to control bram regen 
  reg             dv0;            // "dv0" - one cycle ahead  of "dv" to compensate for "do_r" register latency
  reg             ds0;            // "ds0" - one cycle ahead  of "ds" to compensate for "do_r" register latency
//  reg     [8:0]   do_r;
//  reg     [8:0]   pre_do;
  reg     [9:0]   do_r;
  reg     [9:0]   pre_do;
  reg     [1:0]   pre_dv, pre_ds;

  reg               dv_raw_r;

// 16x8 dual port RAM
   reg               buf_sel;

   reg            willbe_first;
   reg            first_r,first0;
   reg            last_r,last0;
   reg    [4:0]   preline; // number of line in a tile, down counter (0x13->0, 0x11->0, 0x0f->0), 1 cycles ahead of data from SDRAM
   reg    [4:0]   prepix; // number of pixel in a line in a tile, down counter (0x13->0, 0x11->0, 0x0f->0)
   reg    [1:0]   sdram_a9_page;
   reg    [8:0]   sdram_a9;
   reg    [8:0]   seq_cntr; // master
   wire   [4:0]   tile_size;
   wire   [8:0]   macroblock_period_minus1;
   wire           all_ready;
   reg            preline_was_0;
   reg            pre_start_of_line;
   reg            pre_first_pixel;
   reg    [8:0]   sdrama_top_left; // address of top left corner to be processed
   reg    [2:0]   sdrama_line_inc; // increment amount when proceeding to next tile line
   reg    [1:0]   inc_sdrama_r;
   reg            last_from_sdram; // reading last_r byte from SDRAM
   reg            first_pixel; // reading first_r pixel to color converter (di will be available next cycle)
   reg            tim2next;
   reg    [8:0]   y_in, c_in;
   reg    [7:0]   yaddrw, caddrw;
   reg            ywe, cwe;
   reg            color_enable, pre_color_enable;// prevent random colors in monochrome/JP46 modes (pre_* - sync input)
   reg            cs_pre_first_out; // clear color accumulators
   wire   [7:0]   conv18_y_in, conv20_y_in, mono_y_in, jp4_y_in;
   wire   [8:0]   jp4diff_y_in, conv18_c_in, conv20_c_in;
   wire   [7:0]   conv18_yaddrw, conv20_yaddrw, mono_yaddrw, jp4_yaddrw, jp4diff_yaddrw;
   wire   [6:0]   conv18_caddrw, conv20_caddrw;
   wire           conv18_ywe, conv18_cwe, conv20_ywe, conv20_cwe, mono_ywe, jp4_ywe, jp4diff_ywe;
   wire           conv18_pre_first_out, conv20_pre_first_out, mono_pre_first_out, jp4_pre_first_out, jp4diff_pre_first_out;
   reg    [4:0]   en_converters;

   reg    [2:0]   converter_type_r;
   reg            ignore_color_r;
   reg            jp4_dc_improved_r;
   reg            four_blocks_r;
   reg            scale_diff_r;
   reg            hdr_r;
   reg    [1:0]   tile_margin_r;
//   reg    [2:0]   tile_shift_r;
   reg    [1:0]   bayer_phase_r;
   reg    [3:0]   bayer_phase_onehot;


   reg            raddr_lastInBlock;
   reg            raddr_updateBlock; // first_r in block, after last_r also. Should be when *_r match the currently selected  converter for the macroblock
// component_num,component_color,component_first for different converters vs tn (1 bit per tn (0..5)
   reg            component_lastinmb_r; // last_r component in a macroblock;

   reg    [5:0]   component_numsL,  component_numsLS;  // component_num[0] vs tn
   reg    [5:0]   component_numsM,  component_numsMS;  // component_num[1] vs tn
   reg    [5:0]   component_numsH,  component_numsHS;  // component_num[2] vs tn
   reg    [5:0]   component_colors, component_colorsS;  // use color quantization table (YCbCR, jp4diff)
   reg    [5:0]   component_firsts, component_firstsS; // first_r this component in a frame (DC absolute, otherwise - difference to previous)
   reg            eof_rq;  // request to end frame if there will be no more data

`ifdef DEBUG_COMPRESSOR
    assign bcntr = bcntr_r;
    assign bcntrIsZero= bcntrIsZero_r;
`endif    
  assign  component_lastinmb=component_lastinmb_r;
  
    assign sdram_a =      {sdram_a9_page[1:0],sdram_a9[8:0]};
    assign tn[2:0] =      raddr[8:6];
    assign sdram_next =   sdram_next_r;
    assign inc_sdrama =   inc_sdrama_r[0];
    assign inc_sdrama_d = inc_sdrama_r[1];
    assign eot =          eot_r;
    assign first =        first_r;
    assign last =         last_r;
    assign dv_raw =       dv_raw_r;
    assign do =           do_r;
    assign dv =           pre_dv[1];
    assign ds =           pre_ds[1];
    
    assign component_num[2:0]= {component_numsH[0],component_numsM[0],component_numsL[0]};
    assign component_color   = component_colors[0];
    assign component_first   = component_firsts[0];

    assign all_ready =                     sdram_rdy && ccv_start_en;
    assign macroblock_period_minus1[8:0] = four_blocks?(tile_margin[1]?9'h18f:(tile_margin[0]?9'h143:9'h0ff)):(tile_margin[1]?9'h18f:9'h17f);
    assign tile_size[4:0] =                tile_margin[1]?5'h13:(tile_margin[0]?5'h11:5'h0f);
    
   always @ (posedge clk) begin
     if      (!en)              seq_cntr[8:0] <=9'h0;
     else if (seq_cntr[8:0]!=0) seq_cntr[8:0] <= seq_cntr[8:0] -1;
     else if (all_ready)        seq_cntr[8:0] <= macroblock_period_minus1;

     preline_was_0 <= (preline[4:0]==5'h0);
     if      ((seq_cntr[8:0]==0) || ((prepix[4:0]==0) && !preline_was_0) ) prepix[4:0] <= tile_size[4:0];
     else if (prepix[4:0]!=0)                                              prepix[4:0] <= prepix[4:0] - 1;
     if      (seq_cntr[8:0]==0)                                            preline[4:0] <= tile_size[4:0];
     else if ((prepix[4:0]==0) && !preline_was_0)                          preline[4:0] <= preline[4:0] - 1;
     pre_start_of_line <= ((seq_cntr[8:0]==0) || ((prepix[4:0]==0) && !preline_was_0) );
     pre_first_pixel <= en && (seq_cntr[8:0]==9'h0) && all_ready;
     case (tile_shift[2:0])
      3'h0: sdrama_top_left[8:0] <= 9'h0;
      3'h1: sdrama_top_left[8:0] <= 9'h15;
      3'h2: sdrama_top_left[8:0] <= 9'h2a;
      3'h3: sdrama_top_left[8:0] <= 9'h3f;
      3'h4: sdrama_top_left[8:0] <= 9'h54;
     endcase
     case (tile_margin[1:0])
      2'h0: sdrama_line_inc[2:0] <= 3'h5;
      2'h1: sdrama_line_inc[2:0] <= 3'h3;
      2'h2: sdrama_line_inc[2:0] <= 3'h1;
     endcase
     first_pixel <= pre_first_pixel;
     last_from_sdram <= en & preline_was_0 && (prepix[4:0]==0);
     inc_sdrama_r <= en & (pre_first_pixel || (inc_sdrama_r && !last_from_sdram ));
     if      (pre_first_pixel)    sdram_a9[8:0] <= sdrama_top_left[8:0];
     else if (inc_sdrama_r)         sdram_a9[8:0] <= sdram_a9[8:0] + (pre_start_of_line ? sdrama_line_inc[2:0] : 3'h1);

     if      (!en || memWasInit)             sdram_a9_page[1:0] <= 2'h0;
     else if (last_from_sdram && inc_sdrama_r) sdram_a9_page[1:0] <= sdram_a9_page[1:0]+1;
//   wpage[1:0] valid with ywe
     if (cs_pre_first_out) wpage[1:0] <= sdram_a9_page[1:0]; // copy page from SDRAM buffer
// register control modes to be valid while overlapping
     if (pre_first_pixel) begin
        converter_type_r [2:0] <= converter_type[2:0];
        ignore_color_r         <= ignore_color;
        jp4_dc_improved_r      <= jp4_dc_improved;
        four_blocks_r          <= four_blocks;
        scale_diff_r           <= scale_diff;
        hdr_r                  <= hdr;
        tile_margin_r[1:0]     <= tile_margin[1:0];
        bayer_phase_r[1:0]     <= bayer_phase[1:0];
        bayer_phase_onehot[3:0]<={(bayer_phase[1:0]==2'h3)?1'b1:1'b0,
                                  (bayer_phase[1:0]==2'h2)?1'b1:1'b0,
                                  (bayer_phase[1:0]==2'h1)?1'b1:1'b0,
                                  (bayer_phase[1:0]==2'h0)?1'b1:1'b0};


     end
     if (!en) en_converters[4:0] <= 0;
     else if (pre_first_pixel) 
          en_converters[4:0]<= {(converter_type[2:0]==3'h4)?1'b1:1'b0,
                               (converter_type[2:0]==3'h3)?1'b1:1'b0,
                               (converter_type[2:0]==3'h2)?1'b1:1'b0,
                               (converter_type[2:0]==3'h1)?1'b1:1'b0,
                               (converter_type[2:0]==3'h0)?1'b1:1'b0};

   end

// new 
//cs_pre_first_out
   reg  [3:0] accYen;
   reg  [1:0] accCen;    // individual accumulator enable (includes clearing)
   reg  [3:0] accYfirst;
   reg  [1:0] accCfirst; // add to zero, instead of to acc @ acc*en 
   reg  [8:0] preAccY,  preAccC;     // registered data from color converters, matching acc selection latency 
   reg [14:0] accY0,accY1,accY2,accY3,accC0,accC1;
   reg        cs_first_out;
   reg  [5:0] accCntrY0,accCntrY1,accCntrY2,accCntrY3,accCntrC0,accCntrC1;
   wire [3:0] pre_accYdone;
   wire [1:0] pre_accCdone; // need to make sure that pre_accCdone do_r not happen with pre_accYdone
   reg  [3:0] accYrun;
   reg  [1:0] accCrun;
   reg  [3:0] accYdone;
   reg        accYdoneAny;
   reg  [1:0] avrY_wa, pre_avrY_wa;
   reg        avrC_wa, pre_avrC_wa;
   reg        avrPage_wa, pre_avrPage_wa;
   reg        avr_we;
   reg  [8:0] avermem[0:15];
   wire [3:0] avr_wa= {avrPage_wa,accYdoneAny?{1'b0,avrY_wa[1:0]}:{2'b10,avrC_wa}};
   reg  [3:0] avr_ra;  // read address
   wire [8:0] avrY_di= avrY_wa[1] ? (avrY_wa[0]?accY3[14:6]:accY2[14:6]):(avrY_wa[0]?accY1[14:6]:accY0[14:6]);
   wire [8:0] avrC_di= avrC_wa ?accC1[14:6]:accC0[14:6];
   assign  avr  = avermem[avr_ra[3:0]];
   assign pre_accYdone[3:0] = {(accCntrY3[5:0]==6'h3e)?1'b1:1'b0,
                               (accCntrY2[5:0]==6'h3e)?1'b1:1'b0,
                               (accCntrY1[5:0]==6'h3e)?1'b1:1'b0,
                               (accCntrY0[5:0]==6'h3e)?1'b1:1'b0} & accYen[3:0];
   assign pre_accCdone[1:0] = {(accCntrC1[5:0]==6'h3e)?1'b1:1'b0,
                               (accCntrC0[5:0]==6'h3e)?1'b1:1'b0} & accCen[1:0];
   always @ (posedge clk) begin
        cs_first_out<=cs_pre_first_out;
        if (ywe) preAccY[8:0] <= y_in[8:0];
        if (cwe) preAccC[8:0] <= c_in[8:0];
        accYen[3:0] <= {4{en & ywe}} & {yaddrw[7] &  yaddrw[6],
                           yaddrw[7] &  ~yaddrw[6],
                          ~yaddrw[7] &   yaddrw[6],
                          ~yaddrw[7] &  ~yaddrw[6]};
        accCen[1:0] <= {2{en & cwe}} & { caddrw[6],
                                        ~caddrw[6]};
        accYfirst[3:0] <= {4{cs_first_out}} | (accYfirst[3:0] & ~accYen[3:0]);
        accCfirst[1:0] <= {2{cs_first_out}} | (accCfirst[1:0] & ~accCen[1:0]);
        if (accYen[0]) accY0[14:0]<= (accYfirst[0]?15'h0:accY0[14:0]) + {{6{preAccY[8]}},preAccY[8:0]};
        if (accYen[1]) accY1[14:0]<= (accYfirst[1]?15'h0:accY1[14:0]) + {{6{preAccY[8]}},preAccY[8:0]};
        if (accYen[2]) accY2[14:0]<= (accYfirst[2]?15'h0:accY2[14:0]) + {{6{preAccY[8]}},preAccY[8:0]};
        if (accYen[3]) accY3[14:0]<= (accYfirst[3]?15'h0:accY3[14:0]) + {{6{preAccY[8]}},preAccY[8:0]};
        if (accCen[0]) accC0[14:0]<= (accCfirst[0]?15'h0:accC0[14:0]) + {{6{preAccC[8]}},preAccC[8:0]};
        if (accCen[1]) accC1[14:0]<= (accCfirst[1]?15'h0:accC1[14:0]) + {{6{preAccC[8]}},preAccC[8:0]};
        
        if (!en) accCntrY0[5:0]<= 6'h0; else if (accYen[0]) accCntrY0[5:0]<= (accYfirst[0]?6'h0:(accCntrY0[5:0]+1));
        if (!en) accCntrY1[5:0]<= 6'h0; else if (accYen[1]) accCntrY1[5:0]<= (accYfirst[1]?6'h0:(accCntrY1[5:0]+1));
        if (!en) accCntrY2[5:0]<= 6'h0; else if (accYen[2]) accCntrY2[5:0]<= (accYfirst[2]?6'h0:(accCntrY2[5:0]+1));
        if (!en) accCntrY3[5:0]<= 6'h0; else if (accYen[3]) accCntrY3[5:0]<= (accYfirst[3]?6'h0:(accCntrY3[5:0]+1));
        if (!en) accCntrC0[5:0]<= 6'h0; else if (accCen[0]) accCntrC0[5:0]<= (accCfirst[0]?6'h0:(accCntrC0[5:0]+1));
        if (!en) accCntrC1[5:0]<= 6'h0; else if (accCen[1]) accCntrC1[5:0]<= (accCfirst[1]?6'h0:(accCntrC1[5:0]+1));
        
        accYrun[3:0] <= {4{en}} & ((accYfirst[3:0] & accYen[3:0]) | (accYrun[3:0] & ~pre_accYdone[3:0]));
        accCrun[1:0] <= {2{en}} & ((accCfirst[1:0] & accCen[1:0]) | (accCrun[1:0] & ~pre_accCdone[1:0]));
        
        accYdone[3:0] <= pre_accYdone[3:0] & accYrun[3:0];
        accYdoneAny   <= |(pre_accYdone[3:0] & accYrun[3:0]);
        avr_we        <=  |(pre_accYdone[3:0] & accYrun[3:0]) || |(pre_accCdone[1:0] & accCrun[1:0]);
        
        pre_avrY_wa[1:0] <= yaddrw[7:6];
        avrY_wa[1:0]     <= pre_avrY_wa[1:0];
        pre_avrC_wa      <= caddrw[  6];
        avrC_wa          <= pre_avrC_wa;
        pre_avrPage_wa   <= wpage[0];
        avrPage_wa       <= pre_avrPage_wa;
        
        if (avr_we)  avermem[avr_wa[3:0]] <= en_sdc?(accYdoneAny?avrY_di[8:0]:avrC_di[8:0]):9'h0; 
        
        avr_ra[3:0] <= {rpage[0],raddr[8:6]};
        raddr8_d <=    raddr[8];
   end

  reg transfer_ended=0; /// there was already EOT pulse for the current frame
  
  
  always @ (posedge clk) begin
     transfer_ended <= bcntrIsZero_r && (transfer_ended || eot_r);
/*+*/ tim2next <= (seq_cntr[8:0]=='h10); // rather arbitrary number - sdram buffer should in no case be actually overwritten before data read out
                                          // it may depend on relation between SDRAM clk frequency (75MHz) and this clk (variable? 30MHz)
     eof_rq <= (tim2next && !bcntrIsZero_r) || (eof_rq && !(inc_sdrama_r || transfer_ended));

     ccv_start_en <= en && !eot_r && (ccv_start_en || go); //FIXME: Still uncaught problem: SDRAM ready occurs before go_single!
     bcntrIsZero_r <= (bcntr_r==0);
     sdram_next_r <= tim2next && ~sdram_next_r;
     eot_r        <= !transfer_ended && !eot_r && bcntrIsZero_r && (tim2next || (eof_rq && noMoreData));

     if      (go)                         bcntr_r <= nblocks;
     else if (noMoreData)                 bcntr_r <= 0;
     else if (sdram_next_r && !bcntrIsZero_r) bcntr_r <= bcntr_r-1;

      if (ccv_out_start) rpage[1:0]   <=wpage[1:0];
      if (ccv_out_start) color_enable <= pre_color_enable;

     ccv_out_start_d   <= ccv_out_start;
     raddr_lastInBlock <= en && (raddr[5:0]==6'h3e);
     raddr_updateBlock <= raddr_lastInBlock || ccv_out_start;


      if (ccv_out_start || !en) raddr[8:0] <= {!en,!en,7'h0};   // 9'h180/9'h000;
     else if (!raddr[8] || (!four_blocks_r && !raddr[7])) raddr[8:0] <= raddr[8:0]+1; // for 4 blocks - count for 0,1; 6 blocks - 0,1,2

     dv0       <= en && raddr_updateBlock?(!raddr[8] || (!four_blocks_r && !raddr[7])):dv0;
     ds0       <= raddr_updateBlock && (!raddr[8] || (!four_blocks_r && !raddr[7]));

      buf_sel   <= raddr[8];
     pre_do[9:0] <= buf_sel?(color_enable?({c_out[8],c_out[8:0]}-{avr[8],avr[8:0]}):10'b0):({y_out[8],y_out[8:0]}-{avr[8],avr[8:0]});

//color_enable
     do_r[9:0]   <= pre_do[9:0];
     dv_raw_r     <= inc_sdrama_r && en;

     if      (go) willbe_first <= 1'b1;
     else if (first_pixel) willbe_first <= 1'b0;

     if (first_pixel) begin
        first0 <= willbe_first;
         last0  <= (bcntr_r[17:0]==18'b0);
      end
     if (ccv_out_start) begin
        first_r <= first0;
         last_r  <= last0;
      end
// 8x8 memory to hold average values
  pre_dv[1:0] <= {pre_dv[0],dv0};
  pre_ds[1:0] <= {pre_ds[0],ds0};

// Shift registers - generating block attributes to be used later in compressor
     if (raddr_updateBlock) begin
       if (ccv_out_start_d) begin
         component_numsL[5:0]  <= component_numsLS[5:0];
         component_numsM[5:0]  <= component_numsMS[5:0];
         component_numsH[5:0]  <= component_numsHS[5:0];
         component_colors[5:0] <= component_colorsS[5:0];
         component_firsts[5:0] <= first0? component_firstsS[5:0]:6'h0; // here we may use first0 that is one cycle earlier and ends much earlier
       end else begin
         component_numsL[5:0]  <= {1'b0,component_numsL[5:1]};
         component_numsM[5:0]  <= {1'b0,component_numsM[5:1]};
         component_numsH[5:0]  <= {1'b0,component_numsH[5:1]};
         component_colors[5:0] <= {1'b0,component_colors[5:1]};
         component_firsts[5:0] <= {1'b0,component_firsts[5:1]};
       end
     end
     component_lastinmb_r <= tn[0] && (four_blocks_r? tn[1] : tn[2]); // last_r component in a macroblock;
  end
// average for each block should be calculated before the data goes to output output
  always @ (posedge clk) case (converter_type_r[2:0])
    3'h0:begin //color 18
          cs_pre_first_out <= conv18_pre_first_out;
          y_in[8:0]        <= {conv18_y_in[7],conv18_y_in[7:0]};
          ywe              <= conv18_ywe;
          yaddrw[7:0]      <= {conv18_yaddrw[7],conv18_yaddrw[3],conv18_yaddrw[6:4],conv18_yaddrw[2:0]};
          c_in[8:0]        <= {conv18_c_in[8:0]};
          cwe              <= conv18_cwe;
          pre_color_enable <= 1'b1;
          caddrw[7:0]      <= {1'b0,conv18_caddrw[6:0]};
          ccv_out_start    <= (conv18_yaddrw[7:0]==8'hc5); //TODO: adjust to minimal latency?
          component_numsLS  <= 6'h10; // component_num [0]
          component_numsMS  <= 6'h20; // component_num [1]
          component_numsHS  <= 6'h00; // component_num [2]
          component_colorsS <= 6'h30; // use color quantization table (YCbCR, jp4diff)
          component_firstsS <= 6'h31; // first_r this component in a frame (DC absolute, otherwise - difference to previous)
         end
    3'h1:begin //color 20
          cs_pre_first_out <= conv20_pre_first_out;
          y_in[8:0]        <= {conv20_y_in[7],conv20_y_in[7:0]};
          ywe              <= conv20_ywe;
          yaddrw[7:0]      <= {conv20_yaddrw[7],conv20_yaddrw[3],conv20_yaddrw[6:4],conv20_yaddrw[2:0]};
          c_in[8:0]        <= {conv20_c_in[8:0]};
          cwe              <= conv20_cwe;
          pre_color_enable <= 1'b1;
          caddrw[7:0]      <= {1'b0,conv20_caddrw[6:0]};
          ccv_out_start    <= (conv20_yaddrw[7:0]==8'hc5); //TODO: adjust to minimal latency?
          component_numsLS  <= 6'h10; // component_num [0]
          component_numsMS  <= 6'h20; // component_num [1]
          component_numsHS  <= 6'h3f; // component_num [2]
          component_colorsS <= 6'h30; // use color quantization table (YCbCR, jp4diff)
          component_firstsS <= 6'h31; // first_r this component in a frame (DC absolute, otherwise - difference to previous)
         end
    3'h2:begin //mono
          cs_pre_first_out <= mono_pre_first_out;
          y_in[8:0]        <= {mono_y_in[7],mono_y_in[7:0]};
          ywe              <= mono_ywe;
          yaddrw[7:0]      <= {mono_yaddrw[7],mono_yaddrw[3],mono_yaddrw[6:4],mono_yaddrw[2:0]};
          c_in[8:0]        <= 9'h0;
          cwe              <= 1'b0;
             pre_color_enable <= 1'b0;
          caddrw[7:0]      <= 8'h0;
          ccv_out_start    <=  accYdone[0];
          component_numsLS  <= 6'h10; // component_num [0]
          component_numsMS  <= 6'h20; // component_num [1]
          component_numsHS  <= 6'h30; // component_num [2]
          component_colorsS <= 6'h30; // use color quantization table (YCbCR, jp4diff)
          component_firstsS <= 6'h31; // first_r this component in a frame (DC absolute, otherwise - difference to previous)
         end
    3'h3:begin // jp4
          cs_pre_first_out <= jp4_pre_first_out;
          y_in[8:0]        <= {jp4_y_in[7],jp4_y_in[7:0]};
          ywe              <= jp4_ywe;
          yaddrw[7:0]      <= {jp4_yaddrw[7],jp4_yaddrw[3],jp4_yaddrw[6:4],jp4_yaddrw[2:0]};
          c_in[8:0]        <= 9'h0;
          cwe              <= 1'b0;
             pre_color_enable <= 1'b0;
          caddrw[7:0]      <= 8'h0;
          ccv_out_start    <=  accYdone[0];
          component_numsLS  <= jp4_dc_improved_r?6'h0a:6'h10; // LSb of component_num
          component_numsMS  <= jp4_dc_improved_r?6'h0c:6'h20; // MSb of component_num
          component_numsHS  <= 6'h30; // component_num [2]
          component_colorsS <= 6'h30; // use color quantization table (YCbCR, jp4diff)
          component_firstsS <= jp4_dc_improved_r?6'h3f:6'h31; // first_r this component in a frame (DC absolute, otherwise - difference to previous)
         end
    3'h4:begin //jp4diff
          cs_pre_first_out <= jp4diff_pre_first_out;
          y_in[8:0]        <= {jp4diff_y_in[8:0]};
          ywe              <= jp4diff_ywe;
          yaddrw[7:0]      <= {jp4diff_yaddrw[7],jp4diff_yaddrw[3],jp4diff_yaddrw[6:4],jp4diff_yaddrw[2:0]};
          c_in[8:0]        <= 9'h0;
          cwe              <= 1'b0;
             pre_color_enable <= 1'b0;
          caddrw[7:0]      <= 8'h0;
          ccv_out_start    <=  accYdone[0];
          component_numsLS  <= 6'h0a; // LSb of component_num
          component_numsMS  <= 6'h0c; // MSb of component_num
          component_numsHS  <= 6'h30; // component_num [2]
          component_colorsS <= {2'h3,~bayer_phase_onehot[3:0] | (hdr_r? {~bayer_phase_onehot[1:0],~bayer_phase_onehot[3:2]} : 4'h0)}; // use color quantization table (YCbCR, jp4diff)
          component_firstsS <= 6'h3f; // first_r this component in a frame (DC absolute, otherwise - difference to previous)
         end
  endcase

wire limit_diff=1'b1;

 csconvert18a    i_csconvert18 (
                         .RST           (!en_converters[0]),
                         .CLK           (clk),
                         .mono          (ignore_color_r),
                         .limit_diff    (limit_diff), // 1 - limit color outputs to -128/+127 range, 0 - let them be limited downstream
                         .m_cb          (m_cb[9:0]),       // [9:0] scale for CB - default 0.564 (10'h90)
                         .m_cr          (m_cr[9:0]),       // [9:0] scale for CB - default 0.713 (10'hb6)
                         .din           (di[7:0]),
                         .pre_first_in  (first_pixel),
                         .signed_y      (conv18_y_in[7:0]),
                         .q             (conv18_c_in[8:0]),
                         .yaddr         (conv18_yaddrw[7:0]), // 
                         .ywe           (conv18_ywe),
                         .caddr         (conv18_caddrw[6:0]),
                         .cwe           (conv18_cwe),
                         .pre_first_out (conv18_pre_first_out),
                         .bayer_phase   (bayer_phase_r[1:0]),
                         .n000          (n000[7:0]), // TODO:remove ?
                         .n255          (n255[7:0]));

 csconvert_mono i_csconvert_mono (
                         .en            (en_converters[2]),
                         .clk           (clk),
                         .din           (di[7:0]),
                         .pre_first_in  (first_pixel),
                         .y_out         (mono_y_in[7:0]),
                         .yaddr         (mono_yaddrw[7:0]),
                         .ywe           (mono_ywe),
                         .pre_first_out(mono_pre_first_out));
 csconvert_jp4 i_csconvert_jp4 (
                         .en            (en_converters[3]),
                         .clk           (clk),
                         .din           (di[7:0]),
                         .pre_first_in  (first_pixel),
                         .y_out         (jp4_y_in[7:0]),
                         .yaddr         (jp4_yaddrw[7:0]),
                         .ywe           (jp4_ywe),
                         .pre_first_out (jp4_pre_first_out));

 csconvert_jp4diff i_csconvert_jp4diff (
                         .en            (en_converters[4]),
                         .clk           (clk),
                         .scale_diff    (scale_diff_r),
                         .hdr           (hdr_r),
                         .din           (di[7:0]),
                         .pre_first_in  (first_pixel),
                         .y_out         (jp4diff_y_in[8:0]),
                         .yaddr         (jp4diff_yaddrw[7:0]),
                         .ywe           (jp4diff_ywe),
                         .pre_first_out (jp4diff_pre_first_out),
                         .bayer_phase   (bayer_phase_r[1:0]));


//TODO:  temporary plugs, until module for 20x20 is created
// will be wrong, of course
assign conv20_y_in[7:0]=     conv18_y_in[7:0];
assign conv20_yaddrw[7:0]=   conv18_yaddrw[7:0];
assign conv20_ywe=           conv18_ywe;
assign conv20_c_in[8:0]=     conv18_c_in[8:0];
assign conv20_caddrw[6:0]=   conv18_caddrw[6:0];
assign conv20_cwe=           conv18_cwe;
assign conv20_pre_first_out= conv18_pre_first_out;


// currently only 8 bits are used in the memories
    ram18p_var_w_var_r #(
        .REGISTERS    (1), // will need to delay output strobe(s) by 1
        .LOG2WIDTH_WR (3),
        .LOG2WIDTH_RD (3),
        .DUMMY        (0)
    ) i_y_buff (
        .rclk         (clk),                           // input
        .raddr        ({1'b0,rpage[1:0],raddr[7:0]}),  // input[11:0] 
        .ren          (!raddr[8]),                     // input
        .regen        (!raddr8_d),                     // input
        .data_out     (y_out[8:0]),                    // output[8:0] 
        .wclk         (clk),                           // input
        .waddr        ({1'b0,wpage[1:0],yaddrw[7:0]}), // input[11:0] 
        .we           (ywe),                           // input
        .web          (4'hf),                          // input[7:0] 
        .data_in      (y_in[8:0])                      // input[9:0] 
    );

    ram18p_var_w_var_r #(
        .REGISTERS    (1), // will need to delay output strobe(s) by 1
        .LOG2WIDTH_WR (3),
        .LOG2WIDTH_RD (3),
        .DUMMY        (0)
    ) i_CrCb_buff (
        .rclk         (clk),                           // input
        .raddr        ({1'b0,rpage[1:0],raddr[7:0]}),  // input[11:0] 
        .ren          (raddr[8]),                      // input
        .regen        (raddr8_d),                      // input
        .data_out     (c_out[8:0]),                    // output[8:0] 
        .wclk         (clk),                           // input
        .waddr        ({1'b0,wpage[1:0],yaddrw[7:0]}), // input[11:0] 
        .we           (ywe),                           // input
        .web          (4'hf),                          // input[7:0] 
        .data_in      (y_in[8:0])                      // input[71:0] 
    );


/*
   RAMB16_S9_S9 i_y_buff (
      .DOA(),                                  // Port A 8-bit Data Output
      .DOPA(),                                 // Port A 8-bit Parity Output
      .ADDRA({1'b0,wpage[1:0],yaddrw[7:0]}),   // Port A 11-bit Address Input
      .CLKA(clk),                              // Port A Clock
      .DIA(y_in[7:0]),                               // Port A 8-bit Data Input
      .DIPA(y_in[8]),                              // Port A 1-bit parity Input
      .ENA(ywe),                                // Port A RAM Enable Input
      .SSRA(1'b0),                              // Port A Synchronous Set/Reset Input
      .WEA(1'b1),                               // Port A Write Enable Input

      .DOB(y_out[7:0]),                         // Port B 8-bit Data Output
      .DOPB(y_out[8]),                                  // Port B 1-bit Parity Output
      .ADDRB({1'b0,rpage[1:0],raddr[7:0]}),     // Port B 11-bit Address Input
      .CLKB(clk),                               // Port B Clock
      .DIB(8'h0),                               // Port B 8-bit Data Input
      .DIPB(1'h0),                              // Port-B 1-bit parity Input
      .ENB(!raddr[8]),                          // PortB RAM Enable Input
      .SSRB(1'b0),                              // Port B Synchronous Set/Reset Input
      .WEB(1'b0)                                // Port B Write Enable Input
   );
   RAMB16_S9_S9 i_CrCb_buff (
      .DOA(),                                  // Port A 8-bit Data Output
      .DOPA(),                                 // Port A 8-bit Parity Output
      .ADDRA({1'b0,wpage[1:0],caddrw[7:0]}),   // Port A 11-bit Address Input
      .CLKA(clk),                              // Port A Clock
      .DIA(c_in[7:0]),                          // Port A 8-bit Data Input
      .DIPA(c_in[8]),                              // Port A 1-bit parity Input
      .ENA(cwe),                                // Port A RAM Enable Input
      .SSRA(1'b0),                              // Port A Synchronous Set/Reset Input
      .WEA(1'b1),                               // Port A Write Enable Input

      .DOB(c_out[7:0]),                         // Port B 8-bit Data Output
      .DOPB(c_out[8]),                                  // Port B 1-bit Parity Output
      .ADDRB({1'b0,rpage[1:0],raddr[7:0]}),     // Port B 11-bit Address Input
      .CLKB(clk),                               // Port B Clock
      .DIB(8'h0),                               // Port B 8-bit Data Input
      .DIPB(1'h0),                              // Port-B 1-bit parity Input
      .ENB(raddr[8]),                           // PortB RAM Enable Input
      .SSRB(1'b0),                              // Port B Synchronous Set/Reset Input
      .WEB(1'b0)                                // Port B Write Enable Input
   );
*/   
endmodule

