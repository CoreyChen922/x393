/*******************************************************************************
 * Module: cmd_encod_tiled_32_rw
 * Date:2015-02-21  
 * Author: andrey     
 * Description: Combines  cmd_encod_tiled_32_rd and  cmd_encod_tiled_32_wr modules
 *
 * Copyright (c) 2015 <set up in Preferences-Verilog/VHDL Editor-Templates> .
 * cmd_encod_tiled_32_rw.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  cmd_encod_tiled_32_rw.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
`timescale 1ns/1ps

module  cmd_encod_tiled_32_rw #(
    parameter ADDRESS_NUMBER=       15,
    parameter COLADDR_NUMBER=       10,
    parameter CMD_PAUSE_BITS=       10,
    parameter CMD_DONE_BIT=         10,  // VDT BUG: CMD_DONE_BIT is used in a function call parameter!
    parameter FRAME_WIDTH_BITS=     13  // Maximal frame width - 8-word (16 bytes) bursts 
) (
    input                        rst,
    input                        clk,
// programming interface
    input                  [2:0] start_bank,    // bank address
    input   [ADDRESS_NUMBER-1:0] start_row,     // memory row
    input   [COLADDR_NUMBER-4:0] start_col,     // start memory column in 8-bit bursts 
    input [FRAME_WIDTH_BITS:0] rowcol_inc_in, // increment {row.col} when bank rolls over, removed 3 LSBs (in 8-bursts)
    input                  [5:0] num_rows_in_m1,   // number of rows to read minus 1
    input                  [5:0] num_cols_in_m1,   // number of 16-pixel columns to read (rows first, then columns) - 1
    input                        keep_open_in,  // keep banks open (for <=8 banks only
    input                        skip_next_page_in, // do not reset external buffer (continue)    
    input                        start_rd,       // start generating commands by cmd_encod_linear_rd
    input                        start_wr,       // start generating commands by cmd_encod_linear_wr
    output reg                   start,       // this channel was started (1 clk from start_rd || start_wr
    output reg            [31:0] enc_cmd,     // encoded command
    output reg                   enc_wr,      // write encoded command
    output reg                   enc_done     // encoding finished
);
    wire            [31:0] enc_cmd_rd;     // encoded command
    wire                   enc_wr_rd;      // write encoded command
    wire                   enc_done_rd;    // encoding finished
    wire            [31:0] enc_cmd_wr;     // encoded command
    wire                   enc_wr_wr;      // write encoded command
    wire                   enc_done_wr;    // encoding finished
    reg                    select_wr;

   cmd_encod_tiled_32_rd #(
        .ADDRESS_NUMBER (ADDRESS_NUMBER),
        .COLADDR_NUMBER (COLADDR_NUMBER),
        .CMD_PAUSE_BITS (CMD_PAUSE_BITS),
        .CMD_DONE_BIT   (CMD_DONE_BIT)
    ) cmd_encod_tiled_rd_i (
        .rst               (rst), // input
        .clk               (clk), // input
        .start_bank        (start_bank), // input[2:0] 
        .start_row         (start_row), // input[14:0] 
        .start_col         (start_col), // input[6:0] 
        .rowcol_inc_in     (rowcol_inc_in), // input[13:0] // [21:0] 
        .num_rows_in_m1    (num_rows_in_m1), // input[5:0] 
        .num_cols_in_m1    (num_cols_in_m1), // input[5:0] 
        .keep_open_in      (keep_open_in), // input
        .skip_next_page_in (skip_next_page_in), // input
        
        .start             (start_rd), // input
        .enc_cmd           (enc_cmd_rd), // output[31:0] reg 
        .enc_wr            (enc_wr_rd), // output reg 
        .enc_done          (enc_done_rd) // output reg 
    );
 
    cmd_encod_tiled_32_wr #(
        .ADDRESS_NUMBER (ADDRESS_NUMBER),
        .COLADDR_NUMBER (COLADDR_NUMBER),
        .CMD_PAUSE_BITS (CMD_PAUSE_BITS),
        .CMD_DONE_BIT   (CMD_DONE_BIT)
    ) cmd_encod_tiled_wr_i (
        .rst               (rst), // input
        .clk               (clk), // input
        .start_bank        (start_bank), // input[2:0] 
        .start_row         (start_row), // input[14:0] 
        .start_col         (start_col), // input[6:0] 
        .rowcol_inc_in     (rowcol_inc_in), // input[13:0] // [21:0] 
        .num_rows_in_m1    (num_rows_in_m1), // input[5:0] 
        .num_cols_in_m1    (num_cols_in_m1), // input[5:0] 
        .keep_open_in      (keep_open_in), // input
        .skip_next_page_in (skip_next_page_in), // input
        
        .start             (start_wr), // input
        .enc_cmd           (enc_cmd_wr), // output[31:0] reg 
        .enc_wr            (enc_wr_wr), // output reg 
        .enc_done          (enc_done_wr) // output reg 
    );

    always @(posedge rst or posedge clk) begin
        if (rst)       start <= 0;
        else           start <= start_rd || start_wr;

        if      (rst)      select_wr <= 0;
        else if (start_rd) select_wr <= 0;
        else if (start_wr) select_wr <= 1;
    end
    always @(posedge clk) begin
        enc_cmd <= select_wr? enc_cmd_wr: enc_cmd_rd;
        enc_wr <= select_wr? enc_wr_wr: enc_wr_rd;
        enc_done <= select_wr? enc_done_wr: enc_done_rd;
    end

endmodule


