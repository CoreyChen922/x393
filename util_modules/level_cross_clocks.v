/*******************************************************************************
 * Module: level_cross_clocks
 * Date:2015-07-19  
 * Author: Aandrey Filippov     
 * Description: re-sample signal to a different clock to reduce metastability
 *
 * Copyright (c) 2015 Elphel, Inc .
 * level_cross_clocks.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  level_cross_clocks.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
`timescale 1ns/1ps

module  level_cross_clocks#(
    parameter WIDTH = 1,
    parameter REGISTER = 2 // number of registers (>=12)
)(
    input              clk,
    input  [WIDTH-1:0] d_in,
    output [WIDTH-1:0] d_out
);
    generate
        genvar i;
        for (i = 0; i < WIDTH ; i = i+1) begin: level_cross_clock_block
            if (REGISTER <= 1)
                level_cross_clocks_ff_bit    level_cross_clocks_single_i ( // just a single ff (if metastability is not a problem)
                    .clk   (clk),       // input
                    .d_in  (d_in[i]),   // input
                    .d_out (d_out[i])   // output
                );
            else if (REGISTER == 2)
                level_cross_clocks_sync_bit  level_cross_clocks_sync_i ( // classic 2-register synchronizer
                    .clk   (clk),       // input
                    .d_in  (d_in[i]),   // input
                    .d_out (d_out[i])   // output
                );
            else
                level_cross_clocks_single_bit #( // >2 bits (first two only are synchronizer)
                    .REGISTER(REGISTER)
                ) level_cross_clocks_single_i (
                    .clk   (clk),       // input
                    .d_in  (d_in[i]),   // input
                    .d_out (d_out[i])   // output
                );
        end
    endgenerate
endmodule

module  level_cross_clocks_single_bit#(
    parameter REGISTER = 3 // number of registers (>3)
)(
    input   clk,
    input   d_in,
    output  d_out
);
    reg [REGISTER - 3 : 0] regs;
    wire                   d_sync; // after a 2-bit synchronizer
    assign d_out = regs[REGISTER -3];
    always @ (posedge clk) begin
        regs <= (regs << 1) + d_sync; // | d_in complains about widths mismatch
    end
    level_cross_clocks_sync_bit level_cross_clocks_sync_bit_i (
        .clk   (clk), // input
        .d_in  (d_in), // input
        .d_out (d_sync) // output
    );
endmodule

// Classic 2-bit (exactly) synchronizer
module  level_cross_clocks_sync_bit(
    input   clk,
    input   d_in,
    output  d_out
);
`ifndef IGNORE_ATTR
    (* ASYNC_REG = "TRUE" *)
`endif
    reg  [1:0] sync_zer; 
    assign d_out = sync_zer [1];
    always @ (posedge clk) begin
        sync_zer <= {sync_zer[0],d_in};
    end
endmodule

module  level_cross_clocks_ff_bit( // just a single FF if REGISTER == 1 (if metastability is not a problem)
    input       clk,
    input      d_in,
    output reg d_out
);
    always @ (posedge clk) begin
        d_out <= d_in;
    end
endmodule


