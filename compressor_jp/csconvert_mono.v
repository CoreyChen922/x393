/*******************************************************************************
 * Module: csconvert_mono
 * Date:2015-06-10  
 * Author: andrey     
 * Description: Convert JPEG monochrome
 *
 * Copyright (c) 2015 Elphel, Inc.
 * csconvert_mono.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  csconvert_mono.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
`timescale 1ns/1ps

module csconvert_mono (en,
                       clk,
                       din,
                       pre_first_in,
                       y_out,
                       yaddr,
                       ywe,
                       pre_first_out);

    input        en;
    input        clk;           // clock
    input  [7:0] din; // input data in scanline sequence
    input        pre_first_in;      // marks the first input pixel
    output [7:0] y_out;  // output Y (16x16) in scanline sequence. Valid if ys active
    output [7:0] yaddr; // address for the external buffer memory to write 16x16x8bit Y data
    output       ywe;    // wrire enable of Y data
    output       pre_first_out;

    wire         pre_first_out= pre_first_in;
//    wire   [7:0] y_out=         din[7:0];
    wire   [7:0] y_out=         {~din[7],din[6:0]};
    reg    [7:0] yaddr;
    reg          ywe;

    always @ (posedge clk) begin
      ywe <= en & (pre_first_in || (ywe && (yaddr[7:0] !=8'hff)));
      if (!en || pre_first_in) yaddr[7:0] <= 8'h0;
      else if (ywe)            yaddr[7:0] <= yaddr[7:0] + 1;
    end

endmodule

