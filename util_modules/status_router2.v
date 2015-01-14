/*******************************************************************************
 * Module: status_router2
 * Date:2015-01-13  
 * Author: andrey     
 * Description: 2:1 status data router/mux
 *
 * Copyright (c) 2015 <set up in Preferences-Verilog/VHDL Editor-Templates> .
 * status_router2.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  status_router2.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
 //TODO: make a 4-input mux too?
`timescale 1ns/1ps
`define DEBUG_FIFO 1
module  status_router2 (
    input        rst,
    input        clk,
    // 2 input channels 
    input [7:0]  db_in0,
    input        rq_in0,
    output       start_in0, // only for the first cycle, combinatorial
    input [7:0]  db_in1,
    input        rq_in1,
    output       start_in1, // only for the first cycle, combinatorial
    // output (multiplexed) channel
    output [7:0] db_out,
    output       rq_out,
    input        start_out  // only for the first cycle, combinatorial
);
    wire           [1:0] rq_in={rq_in1,rq_in0};
    wire           [1:0] start_rcv;
    reg            [1:0] rcv_rest_r; // receiving remaining (after first) bytes
    wire           [1:0] fifo_half_full;
    
    assign         start_in0=start_rcv[0];
    assign         start_in1=start_rcv[1];

    assign start_rcv=~fifo_half_full & ~rcv_rest_r & rq_in;
    wire   [7:0] fifo0_out;
    wire   [7:0] fifo1_out;
    wire   [1:0] fifo_last_byte;
    wire   [1:0] fifo_nempty;
    wire   [1:0] fifo_re;
    reg          next_chn;
    reg          current_chn_r;
    reg          snd_rest_r;
    wire         snd_pre_start; 
    wire         snd_last_byte;
    wire         chn_sel_w;
    wire         early_chn;

    assign       chn_sel_w=(&fifo_nempty)?next_chn:&fifo_nempty[1];
    assign       fifo_re=start_out?{chn_sel_w,~chn_sel_w}:(snd_rest_r?{current_chn_r,~current_chn_r}:2'b0);
    
    assign snd_last_byte=current_chn_r?fifo_last_byte[1]:fifo_last_byte[0];
    assign snd_pre_start=|fifo_nempty && (!snd_rest_r || snd_last_byte);
    assign rq_out=(snd_rest_r && !snd_last_byte) || |fifo_nempty;
    assign early_chn= (snd_rest_r & ~snd_last_byte)?current_chn_r:chn_sel_w;
    assign db_out=early_chn?fifo1_out:fifo0_out;
    always @ (posedge rst or posedge clk) begin
        if (rst) rcv_rest_r<= 0;
        else rcv_rest_r <= (rcv_rest_r & rq_in) | start_rcv;
    
        if (rst) next_chn<= 0;
        else if (|fifo_re) next_chn <= fifo_re[0];
        if (rst) current_chn_r<= 0;
        else if (snd_pre_start) current_chn_r <= chn_sel_w;

        if (rst) snd_rest_r<= 0;
        else snd_rest_r <= (snd_rest_r & ~snd_last_byte) | start_out;
    end
    
/* fifo_same_clock has currently latency of 2 cycles, use smth. faster here? - fifo_1cycle (but it has unregistered data output) */
    fifo_1cycle #(
        .DATA_WIDTH(9),
        .DATA_DEPTH(4) // 16
    ) fifo_in0_i (
        .rst       (rst), // input
        .clk       (clk), // input
        .we        (start_rcv[0] || rcv_rest_r[0]), // input
        .re        (fifo_re[0]), // input
        .data_in   ({rcv_rest_r[0] & ~rq_in[0], db_in0}), // input[8:0] MSB marks last byte
        .data_out  ({fifo_last_byte[0],fifo0_out}), // output[8:0]
        .nempty    (fifo_nempty[0]), // output
        .half_full (fifo_half_full[0]) // output reg 
`ifdef DEBUG_FIFO
        ,.under(), // output reg 
        .over(), // output reg 
        .wcount(), // output[3:0] reg 
        .rcount(), // output[3:0] reg 
        .num_in_fifo() // output[3:0]
`endif         
    );

    fifo_1cycle #(
        .DATA_WIDTH(9),
        .DATA_DEPTH(4) // 16
    ) fifo_in1_i (
        .rst       (rst), // input
        .clk       (clk), // input
        .we        (start_rcv[1] || rcv_rest_r[1]), // input
        .re        (fifo_re[1]), // input
        .data_in   ({rcv_rest_r[1] & ~rq_in[1], db_in1}), // input[8:0] MSB marks last byte
        .data_out  ({fifo_last_byte[1],fifo1_out}), // output[8:0]
        .nempty    (fifo_nempty[1]), // output
        .half_full (fifo_half_full[1]) // output reg 
`ifdef DEBUG_FIFO
        ,.under(), // output reg 
        .over(), // output reg 
        .wcount(), // output[3:0] reg 
        .rcount(), // output[3:0] reg 
        .num_in_fifo() // output[3:0]
`endif         
    );
      
// one car per green (round robin priority)
// start sending out with  with one cycle latency - now 2 cycles because of the FIFO

endmodule

