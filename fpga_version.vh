 /*******************************************************************************
 * File: fpga_version.vh
 * Date:2015-08-26  
 * Author: Andrey Filippov     
 * Description: Defining run-time readable FPGA code version
 *
 * Copyright (c) 2015 Elphel, Inc.
 * fpga_version.vh is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * fpga_version.vh is distributed in the hope that it will be useful,
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
      parameter FPGA_VERSION =          32'h03930073;  // Adding interrupts support
//      parameter FPGA_VERSION =          32'h03930072;  // Adding hact monitor bit 77.9%, failed timing
//    parameter FPGA_VERSION =          32'h03930071;  // Fixing AXI HP multiplexer xclk -0.083 -1.968 44 / 15163 (77.17%)
//    parameter FPGA_VERSION =          32'h03930070;  // Fixing HiSPi xclk -0.049 -0.291 17, utilization 15139 (77.04%)
//    parameter FPGA_VERSION =          32'h0393006f;  // Fixing JP4 mode - xcl -0.002 -0.004 2, utilization 15144 (77.07 %)
//    parameter FPGA_VERSION =          32'h0393006f; // Fixing JP4 mode - xclk -0.209/-2.744/23, utilization  15127 (76.98%)
//    parameter FPGA_VERSION =          32'h0393006e; // Trying lane switch again after bug fix, failing 1 in  ddr3_mclk -> ddr3_clk_div by  -0.023
//    parameter FPGA_VERSION =          32'h0393006d; // -1 with lane switch - does not work
//    parameter FPGA_VERSION =          32'h0393006d; // Reversing pixels/lanes order xclk violated -0.154
//    parameter FPGA_VERSION =          32'h0393006c; // will try debug for HiSPi.  xclk violated by -0.030, slices 15062 (76.65%)
//    parameter FPGA_VERSION =          32'h0393006b; // Correcting sensor external clock generation - was wrong division. xclk violated by 0.095 ns
//    parameter FPGA_VERSION =          32'h0393006a; // modified clock generation, trying with HiSPi - 72.77% utilization x40..x60
//    parameter FPGA_VERSION =          32'h03930069; // modified clock generation, rebuilding for parallel sensors - all met, 71.8% utilization
                                                      // Worked OK, but different phase for sensor 0 (all quadrants as 1,3 OK)
//    parameter FPGA_VERSION =          32'h03930068; // trying BUFR/FUFIO on all sensors ipclk/ipclk2x
//    parameter FPGA_VERSION =          32'h03930067; // removing DUMMY_TO_KEEP, moving IOSTANDARD to HDL code
//    parameter FPGA_VERSION =          32'h03930066; // trying just one histogram to watch utilization - with 4 was: Slice 15913 (80.98%), now Slice = 14318 (72.87%)
//    parameter FPGA_VERSION =          32'h03930065; // (same rev) all met,  using "old" (non-inverted) phase - OK (full phase range)
//    parameter FPGA_VERSION =          32'h03930065; // switch phy_top.v (all met) - OK with inverted phase control (reduced phase range)
//    parameter FPGA_VERSION =          32'h03930064; // switch mcomtr_sequencer.v  (xclk not met) - wrong!
//    parameter FPGA_VERSION =          32'h03930063; // switch mcntrl_linear_rw.v (met) good, worse mem valid phases 
//    parameter FPGA_VERSION =          32'h03930062; // (met)debugging - what was broken (using older versions of some files) - mostly OK (some glitches)
//    parameter FPGA_VERSION =          32'h03930061; // restored bufr instead of bufio for memory high speed clock
//    parameter FPGA_VERSION =          32'h03930060; // moving CLK1..3 in memory controller MMCM, keeping CLK0 and FB. Stuck at memory calib 
//    parameter FPGA_VERSION =          32'h0393005f; // restored mclk back to 200KHz, registers added to csconvert18a
//    parameter FPGA_VERSION =          32'h0393005e; // trying mclk = 225 MHz (was 200MHz) define MCLK_VCO_MULT 18
//    parameter FPGA_VERSION =          32'h0393005d; // trying mclk = 250 MHz (was 200MHz) define MCLK_VCO_MULT 20
//    parameter FPGA_VERSION =          32'h0393005c; // 250MHz OK, no timing violations
//    parameter FPGA_VERSION =          32'h0393005b; // 250MHz Not tested, timing violation in bit_stuffer_escape: xclk -0.808 -142.047 515
//    parameter FPGA_VERSION =          32'h0393005a; // Trying xclk = 250MHz - timing viloations in xdct393, but particular hardware works
//    parameter FPGA_VERSION =          32'h03930059; // 'new' (no pclk2x, no xclk2x  clocks) sensor/converter w/o debug - OK
//    parameter FPGA_VERSION =          32'h03930058; // 'new' (no pclk2x, no xclk2x  clocks) sensor/converter w/o debug - broken end of frame
//    parameter FPGA_VERSION =          32'h03930057; // 'new' (no pclk2x, yes xclk2x  clocks) sensor/converter w/o debug - OK
//    parameter FPGA_VERSION =          32'h03930056; // 'new' (no 2x clocks) sensor/converter w/o debug - broken
//    parameter FPGA_VERSION =          32'h03930055; // 'old' sensor/converter w/o debug, fixed bug with irst - OK
//    parameter FPGA_VERSION =          32'h03930054; // 'old' sensor/converter with debug
//    parameter FPGA_VERSION =          32'h03930053; // trying if(reset ) reg <- 'bx    