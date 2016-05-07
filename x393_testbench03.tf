/*******************************************************************************
 * Module: x393_testbench03
 * Date:2015-02-06  
 * Author: Andrey Filippov     
 * Description: testbench for the initial x393.v simulation
 *
 * Copyright (c) 2015 Elphel, Inc.
 * x393_testbench03.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  x393_testbench03.tf is distributed in the hope that it will be useful,
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
`include "system_defines.vh"
`define SAME_SENSOR_DATA  1
//`undef SAME_SENSOR_DATA
`define COMPRESS_SINGLE
`define USE_CMPRS_IRQ
`define USE_FRAME_SEQ_IRQ
//`define use200Mhz 1
//`define DEBUG_FIFO 1
`undef WAIT_MRS
`define SET_PER_PIN_DELAYS 1 // set individual (including per-DQ pin delays)
`define READBACK_DELAYS 1

//`define TEST_MEMBRIDGE 1 // was not set
`undef TEST_MEMBRIDGE // was not set

`define PS_PIO_WAIT_COMPLETE 0 // wait until PS PIO module finished transaction before starting a new one
// Disabled already passed test to speedup simulation
//`define TEST_WRITE_LEVELLING 1
//`define TEST_READ_PATTERN 1
//`define TEST_WRITE_BLOCK 1
//`define TEST_READ_BLOCK 1
//`define TEST_SCANLINE_WRITE
    `define TEST_SCANLINE_WRITE_WAIT 1 // wait TEST_SCANLINE_WRITE finished (frame_done)
//`define TEST_SCANLINE_READ
    `define TEST_READ_SHOW  1
//`define TEST_TILED_WRITE  1
    `define TEST_TILED_WRITE_WAIT 1 // wait TEST_SCANLINE_WRITE finished (frame_done)
//`define TEST_TILED_READ  1

//`define TEST_TILED_WRITE32  1
//`define TEST_TILED_READ32  1

//`define TEST_AFI_WRITE 1
//`define TEST_AFI_READ 1

`define TEST_SENSOR 0


module  x393_testbench03 #(
`include "includes/x393_parameters.vh" // SuppressThisWarning VEditor - not used
`include "includes/x393_simulation_parameters.vh"
)(
);
`ifdef IVERILOG              
//    $display("IVERILOG is defined");
    `ifdef NON_VDT_ENVIROMENT
        parameter fstname="x393.fst";
    `else
        `include "IVERILOG_INCLUDE.v"
    `endif // NON_VDT_ENVIROMENT
`else // IVERILOG
//    $display("IVERILOG is not defined");
    `ifdef CVC
        `ifdef NON_VDT_ENVIROMENT
            parameter fstname = "x393.fst";
        `else // NON_VDT_ENVIROMENT
            `include "IVERILOG_INCLUDE.v"
        `endif // NON_VDT_ENVIROMENT
    `else
        parameter fstname = "x393.fst";
    `endif // CVC
`endif // IVERILOG
`define DEBUG_WR_SINGLE 1  
`define DEBUG_RD_DATA 1  

//`include "includes/x393_cur_params_sim.vh" // parameters that may need adjustment, should be before x393_localparams.vh
`include "includes/x393_cur_params_target.vh" // SuppressThisWarning VEditor - not used parameters that may need adjustment, should be before x393_localparams.vh
parameter TRIGGER_MODE =          0; // 1;     // 0 - auto, 1 - triggered
parameter EXT_TRIGGER_MODE =      1 ;    // 0 - internal, 1 - external trigger (camsync)
parameter EXTERNAL_TIMESTAMP =    0; // 1 ;    // embed local timestamp, 1 - embed received timestamp
parameter NUM_INTERRUPTS =        9;

`include "includes/x393_localparams.vh" // SuppressThisWarning VEditor - not used
// VDT - incorrect  real number calculation
//  localparam       FRAME_COMPRESS_CYCLES_INPUT=(FRAME_COMPRESS_CYCLES * CLK0_PER) /CLK1_PER;  
//  localparam  real FRAME_COMPRESS_CYCLES_INPUT=(CLK0_PER * CLK0_PER);  
// ========================== parameters from x353 ===================================

`ifdef SYNC_COMPRESS
    parameter DEPEND=1'b1;
`else  
    parameter DEPEND=1'b0;
`endif

`ifdef TEST_ABORT
`endif
 
  parameter SYNC_BIT_LENGTH=8-1; /// 7 pixel clock pulses
  parameter FPGA_XTRA_CYCLES= 1500; // 1072+;
// moved to x393_simulation_parameters.vh
//  parameter HISTOGRAM_LEFT=  0; //2;   // left   
//  parameter HISTOGRAM_TOP =  2;   // top
//  parameter HISTOGRAM_WIDTH= 6;  // width
//  parameter HISTOGRAM_HEIGHT=6;  // height
  
  parameter CLK0_PER = 6.25;   //160MHz
  parameter CLK1_PER = 10.4;     //96MHz
  parameter CLK3_PER = 83.33;   //12MHz
  parameter CPU_PER=10.4;
  
 parameter TRIG_PERIOD =      6000 ;
`ifdef HISPI 
    parameter HBLANK=            92; // 72; // 62; // 52; // 90; // 12; /// 52; //*********************
    parameter BLANK_ROWS_BEFORE= 3; // 9; // 3; //8; ///2+2 - a little faster than compressor
    parameter BLANK_ROWS_AFTER=  1; //8;
    
`else
//    parameter HBLANK=            12; // 52; // 12; /// 52; //*********************
    parameter HBLANK=            52; // 12; // 52; // 12; /// 52; //*********************
    parameter BLANK_ROWS_BEFORE= 8;  // 1; //8; ///2+2 - a little faster than compressor
    parameter BLANK_ROWS_AFTER=  8; // 1; //8;
`endif 
 parameter WOI_HEIGHT=        32;
 parameter TRIG_LINES=        8;
 parameter VBLANK=            2; /// 2 lines //SuppressThisWarning Veditor UNUSED
 parameter CYCLES_PER_PIXEL=  3; /// 2 for JP4, 3 for JPEG

`ifdef PF
  parameter PF_HEIGHT=8;
  parameter FULL_HEIGHT=WOI_HEIGHT;
  parameter PF_STRIPES=WOI_HEIGHT/PF_HEIGHT;
`else  
  parameter PF_HEIGHT=0;
  parameter FULL_HEIGHT=WOI_HEIGHT+4;
  parameter PF_STRIPES=0;
`endif

 parameter VIRTUAL_WIDTH=    FULL_WIDTH + HBLANK;
 parameter VIRTUAL_HEIGHT=   FULL_HEIGHT + BLANK_ROWS_BEFORE + BLANK_ROWS_AFTER;  //SuppressThisWarning Veditor UNUSED
 
 parameter TRIG_INTERFRAME=  100; /// extra 100 clock cycles between frames  //SuppressThisWarning Veditor UNUSED

/// parameter TRIG_OUT_DATA=        'h80000; // internal cable
/// parameter TRIG_EXTERNAL_INPUT=  'h20000; // internal cable, low level on EXT[8]

 parameter TRIG_DELAY=      200; /// delay in sensor clock cycles


 parameter FULL_WIDTH=        WOI_WIDTH+4;

  localparam       SENSOR_MEMORY_WIDTH_BURSTS = (FULL_WIDTH + 15) >> 4;
  localparam       SENSOR_MEMORY_MASK = (1 << (FRAME_WIDTH_ROUND_BITS-4)) -1;
  localparam       SENSOR_MEMORY_FULL_WIDTH_BURSTS = (SENSOR_MEMORY_WIDTH_BURSTS + SENSOR_MEMORY_MASK) & (~SENSOR_MEMORY_MASK); 

//  localparam       FRAME_COMPRESS_CYCLES = (WOI_WIDTH &'h3fff0) * (WOI_HEIGHT &'h3fff0) * CYCLES_PER_PIXEL + FPGA_XTRA_CYCLES;
// in pixel clocks (camsync now has different clock - 100MHz instead of the 96MHz
//  localparam       TRIG_PERIOD =   VIRTUAL_WIDTH * (VIRTUAL_HEIGHT + TRIG_LINES + VBLANK); /// maximal sensor can do

// ========================== end of parameters from x353 ===================================



// Sensor signals - as on sensor pads
    wire        PX1_MCLK; // input sensor input clock
    wire        PX1_MRST; // input 
    wire        PX1_ARO;  // input 
    wire        PX1_ARST; // input 
    wire        PX1_OFST = 1'b1; // input // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
    wire [11:0] PX1_D;    // output[11:0] 
    wire        PX1_DCLK; // output sensor output clock (connect to sensor BPF output )
    wire        PX1_HACT; // output 
    wire        PX1_VACT; // output 

    wire        PX2_MCLK; // input sensor input clock
    wire        PX2_MRST; // input 
    wire        PX2_ARO;  // input 
    wire        PX2_ARST; // input 
    wire        PX2_OFST = 1'b1; // input // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
    wire [11:0] PX2_D;    // output[11:0] 
    wire        PX2_DCLK; // output sensor output clock (connect to sensor BPF output )
    wire        PX2_HACT; // output 
    wire        PX2_VACT; // output 

    wire        PX3_MCLK; // input sensor input clock
    wire        PX3_MRST; // input 
    wire        PX3_ARO;  // input 
    wire        PX3_ARST; // input 
    wire        PX3_OFST = 1'b1; // input // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
    wire [11:0] PX3_D;    // output[11:0] 
    wire        PX3_DCLK; // output sensor output clock (connect to sensor BPF output )
    wire        PX3_HACT; // output 
    wire        PX3_VACT; // output 

    wire        PX4_MCLK; // input sensor input clock
    wire        PX4_MRST; // input 
    wire        PX4_ARO;  // input 
    wire        PX4_ARST; // input 
    wire        PX4_OFST = 1'b1; // input // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
    wire [11:0] PX4_D;    // output[11:0] 
    wire        PX4_DCLK; // output sensor output clock (connect to sensor BPF output )
    wire        PX4_HACT; // output 
    wire        PX4_VACT; // output 

    wire       PX1_MCLK_PRE;       // input to pixel clock mult/divisor       // SuppressThisWarning VEditor - may be unused
    wire       PX2_MCLK_PRE;       // input to pixel clock mult/divisor       // SuppressThisWarning VEditor - may be unused
    wire       PX3_MCLK_PRE;       // input to pixel clock mult/divisor       // SuppressThisWarning VEditor - may be unused
    wire       PX4_MCLK_PRE;       // input to pixel clock mult/divisor       // SuppressThisWarning VEditor - may be unused

// Sensor signals - as on FPGA pads
    wire [ 7:0] sns1_dp;   // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
    wire [ 7:0] sns1_dn;   // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
    wire        sns1_clkp; // inout CNVCLK/TDO
    wire        sns1_clkn; // inout CNVSYNC/TDI
    wire        sns1_scl;  // inout PX_SCL
    wire        sns1_sda;  // inout PX_SDA
    wire        sns1_ctl;  // inout PX_ARO/TCK
    wire        sns1_pg;   // inout SENSPGM

    wire [ 7:0] sns2_dp;   // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
    wire [ 7:0] sns2_dn;   // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
    wire        sns2_clkp; // inout CNVCLK/TDO
    wire        sns2_clkn; // inout CNVSYNC/TDI
    wire        sns2_scl;  // inout PX_SCL
    wire        sns2_sda;  // inout PX_SDA
    wire        sns2_ctl;  // inout PX_ARO/TCK
    wire        sns2_pg;   // inout SENSPGM

    wire [ 7:0] sns3_dp;   // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
    wire [ 7:0] sns3_dn;   // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
    wire        sns3_clkp; // inout CNVCLK/TDO
    wire        sns3_clkn; // inout CNVSYNC/TDI
    wire        sns3_scl;  // inout PX_SCL
    wire        sns3_sda;  // inout PX_SDA
    wire        sns3_ctl;  // inout PX_ARO/TCK
    wire        sns3_pg;   // inout SENSPGM

    wire [ 7:0] sns4_dp;   // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
    wire [ 7:0] sns4_dn;   // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
    wire        sns4_clkp; // inout CNVCLK/TDO
    wire        sns4_clkn; // inout CNVSYNC/TDI
    wire        sns4_scl;  // inout PX_SCL
    wire        sns4_sda;  // inout PX_SDA
    wire        sns4_ctl;  // inout PX_ARO/TCK
    wire        sns4_pg;   // inout SENSPGM

// Keep signals defined even if HISPI is not, to preserve non-existing signals in .sav files of gtkwave    
`ifdef HISPI
    localparam PIX_CLK_DIV =          1; // scale clock from FPGA to sensor pixel clock
    localparam PIX_CLK_MULT =        11; // scale clock from FPGA to sensor pixel clock
`else    
    localparam PIX_CLK_DIV =          1; // scale clock from FPGA to sensor pixel clock
    localparam PIX_CLK_MULT =         1; // scale clock from FPGA to sensor pixel clock
`endif
`ifdef HISPI
    localparam HISPI_FULL_HEIGHT =    FULL_HEIGHT;  // >0 - count lines, ==0 - wait for the end of VACT
    localparam HISPI_CLK_DIV =        3; // from pixel clock to serial output pixel rate TODO: Set real ones, adjsut sensor clock too
    localparam HISPI_CLK_MULT =      10; // from pixel clock to serial output pixel rate TODO: Set real ones, adjsut sensor clock too

    localparam HISPI_EMBED_LINES =    2; // first lines will be marked as "embedded" (non-image data)
//    localparam HISPI_MSB_FIRST =      0; // 0 - serialize LSB first, 1 - MSB first
    localparam HISPI_FIFO_LOGDEPTH = 12; // 49-bit wide FIFO address bits (>log (line_length + 2)
`endif    
    
//`ifdef HISPI
    wire [3:0] PX1_LANE_P;         // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX1_LANE_N;         // SuppressThisWarning VEditor - may be unused
    wire       PX1_CLK_P;          // SuppressThisWarning VEditor - may be unused
    wire       PX1_CLK_N;          // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX1_GP;             // Sensor input          // SuppressThisWarning VEditor - may be unused
    wire       PX1_FLASH = 1'bx;   // Sensor output - not yet defined          // SuppressThisWarning VEditor - may be unused
    wire       PX1_SHUTTER = 1'bx; // Sensor output - not yet defined         // SuppressThisWarning VEditor - may be unused

    wire [3:0] PX2_LANE_P;         // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX2_LANE_N;         // SuppressThisWarning VEditor - may be unused
    wire       PX2_CLK_P;          // SuppressThisWarning VEditor - may be unused
    wire       PX2_CLK_N;          // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX2_GP;             // Sensor input          // SuppressThisWarning VEditor - may be unused
    wire       PX2_FLASH = 1'bx;   // Sensor output - not yet defined          // SuppressThisWarning VEditor - may be unused
    wire       PX2_SHUTTER = 1'bx; // Sensor output - not yet defined         // SuppressThisWarning VEditor - may be unused

    wire [3:0] PX3_LANE_P;         // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX3_LANE_N;         // SuppressThisWarning VEditor - may be unused
    wire       PX3_CLK_P;          // SuppressThisWarning VEditor - may be unused
    wire       PX3_CLK_N;          // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX3_GP;             // Sensor input          // SuppressThisWarning VEditor - may be unused
    wire       PX3_FLASH = 1'bx;   // Sensor output - not yet defined          // SuppressThisWarning VEditor - may be unused
    wire       PX3_SHUTTER = 1'bx; // Sensor output - not yet defined         // SuppressThisWarning VEditor - may be unused
    
    wire [3:0] PX4_LANE_P;         // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX4_LANE_N;         // SuppressThisWarning VEditor - may be unused
    wire       PX4_CLK_P;          // SuppressThisWarning VEditor - may be unused
    wire       PX4_CLK_N;          // SuppressThisWarning VEditor - may be unused
    wire [3:0] PX4_GP;             // Sensor input          // SuppressThisWarning VEditor - may be unused
    wire       PX4_FLASH = 1'bx;   // Sensor output - not yet defined          // SuppressThisWarning VEditor - may be unused
    wire       PX4_SHUTTER = 1'bx; // Sensor output - not yet defined         // SuppressThisWarning VEditor - may be unused
//`endif    

`ifdef HISPI
    assign sns1_dp[3:0] =  PX1_LANE_P;
    assign sns1_dn[3:0] =  PX1_LANE_N;
    assign sns1_clkp =     PX1_CLK_P;
    assign sns1_clkn =     PX1_CLK_N;
    // non-HiSPi signals
    assign sns1_dp[4] =    PX1_FLASH;
    assign sns1_dn[4] =    PX1_SHUTTER;
    assign PX1_GP[3:0] = {sns1_dn[7],sns1_dn[6], sns1_dn[5], sns1_dp[5]};
    assign PX1_MCLK_PRE =  sns1_dp[6]; // from FPGA to sensor
    assign PX1_MRST =      sns1_dp[7]; // from FPGA to sensor
    assign PX1_ARST =      sns1_dn[7]; // same as GP[3]
    assign PX1_ARO =       sns1_dn[5]; // same as GP[1]
    
    assign sns2_dp[3:0] =  PX2_LANE_P;
    assign sns2_dn[3:0] =  PX2_LANE_N;
    assign sns2_clkp =     PX2_CLK_P;
    assign sns2_clkn =     PX2_CLK_N;
    // non-HiSPi signals
    assign sns2_dp[4] =    PX1_FLASH;
    assign sns2_dn[4] =    PX2_SHUTTER;
    assign PX2_GP[3:0] = {sns2_dn[7],sns2_dn[6], sns2_dn[5], sns2_dp[5]};
    assign PX2_MCLK_PRE =  sns2_dp[6]; // from FPGA to sensor
    assign PX2_MRST =      sns2_dp[7]; // from FPGA to sensor
    assign PX2_ARST =      sns2_dn[7]; // same as GP[3]
    assign PX2_ARO =       sns2_dn[5]; // same as GP[1]
    
    assign sns3_dp[3:0] =  PX3_LANE_P;
    assign sns3_dn[3:0] =  PX3_LANE_N;
    assign sns3_clkp =     PX3_CLK_P;
    assign sns3_clkn =     PX3_CLK_N;
    // non-HiSPi signals
    assign sns3_dp[4] =    PX3_FLASH;
    assign sns3_dn[4] =    PX3_SHUTTER;
    assign PX3_GP[3:0] = {sns3_dn[7],sns3_dn[6], sns3_dn[5], sns3_dp[5]};
    assign PX3_MCLK_PRE =  sns3_dp[6]; // from FPGA to sensor
    assign PX3_MRST =      sns3_dp[7]; // from FPGA to sensor
    assign PX3_ARST =      sns3_dn[7]; // same as GP[3]
    assign PX3_ARO =       sns3_dn[5]; // same as GP[1]
    
    assign sns4_dp[3:0] =  PX4_LANE_P;
    assign sns4_dn[3:0] =  PX4_LANE_N;
    assign sns4_clkp =     PX4_CLK_P;
    assign sns4_clkn =     PX4_CLK_N;
    // non-HiSPi signals
    assign sns4_dp[4] =    PX4_FLASH;
    assign sns4_dn[4] =    PX4_SHUTTER;
    assign PX4_GP[3:0] = {sns4_dn[7],sns4_dn[6], sns4_dn[5], sns4_dp[5]};
    assign PX4_MCLK_PRE =  sns4_dp[6]; // from FPGA to sensor
    assign PX4_MRST =      sns4_dp[7]; // from FPGA to sensor
    assign PX4_ARST =      sns4_dn[7]; // same as GP[3]
    assign PX4_ARO =       sns4_dn[5]; // same as GP[1]
`else
    //connect parallel12 sensor to sensor port 1
    assign sns1_dp[6:1] =  {PX1_D[10], PX1_D[8], PX1_D[6], PX1_D[4], PX1_D[2], PX1_HACT};
    assign PX1_MRST =       sns1_dp[7]; // from FPGA to sensor
    assign PX1_MCLK_PRE =   sns1_dp[0]; // from FPGA to sensor
    assign sns1_dn[6:0] =  {PX1_D[11], PX1_D[9], PX1_D[7], PX1_D[5], PX1_D[3], PX1_VACT, PX1_DCLK};
    assign PX1_ARST =       sns1_dn[7];
    assign sns1_clkn =      PX1_D[0];  // inout CNVSYNC/TDI
    assign sns1_clkp =      PX1_D[1];  // CNVCLK/TDO
    assign PX1_ARO =       sns1_ctl;  // from FPGA to sensor

    assign PX2_MRST =       sns2_dp[7]; // from FPGA to sensor
    assign PX2_MCLK_PRE =   sns2_dp[0]; // from FPGA to sensor
    assign PX2_ARST =       sns2_dn[7];
    assign PX2_ARO =        sns2_ctl;  // from FPGA to sensor
    
    assign PX3_MRST =       sns3_dp[7]; // from FPGA to sensor
    assign PX3_MCLK_PRE =   sns3_dp[0]; // from FPGA to sensor
    assign PX3_ARST =       sns3_dn[7];
    assign PX3_ARO =        sns3_ctl;  // from FPGA to sensor
    
    assign PX4_MRST =       sns4_dp[7]; // from FPGA to sensor
    assign PX4_MCLK_PRE =   sns4_dp[0]; // from FPGA to sensor
    assign PX4_ARST =       sns4_dn[7];
    assign PX4_ARO =        sns4_ctl;  // from FPGA to sensor

    
`ifdef SAME_SENSOR_DATA
    assign sns2_dp[6:1] =  {PX2_D[10], PX2_D[8], PX2_D[6], PX2_D[4], PX2_D[2], PX2_HACT};
    assign sns2_dn[6:0] =  {PX2_D[11], PX2_D[9], PX2_D[7], PX2_D[5], PX2_D[3], PX2_VACT, PX2_DCLK};
    assign sns2_clkn =      PX2_D[0];  // inout CNVSYNC/TDI
    assign sns2_clkp =      PX2_D[1];  // CNVCLK/TDO

    assign sns3_dp[6:1] =  {PX3_D[10], PX3_D[8], PX3_D[6], PX3_D[4], PX3_D[2], PX3_HACT};
    assign sns3_dn[6:0] =  {PX3_D[11], PX3_D[9], PX3_D[7], PX3_D[5], PX3_D[3], PX3_VACT, PX3_DCLK};
    assign sns3_clkn =      PX3_D[0];  // inout CNVSYNC/TDI
    assign sns3_clkp =      PX3_D[1];  // CNVCLK/TDO

    assign sns4_dp[6:1] =  {PX4_D[10], PX4_D[8], PX4_D[6], PX4_D[4], PX4_D[2], PX4_HACT};
    assign sns4_dn[6:0] =  {PX4_D[11], PX4_D[9], PX4_D[7], PX4_D[5], PX4_D[3], PX4_VACT, PX4_DCLK};
    assign sns4_clkn =      PX4_D[0];  // inout CNVSYNC/TDI
    assign sns4_clkp =      PX4_D[1];  // CNVCLK/TDO

`else    
    //connect parallel12 sensor to sensor port 2 (all data rotated left by 1 bit)
    assign sns2_dp[6:1] =  {PX2_D[9], PX2_D[7], PX2_D[5], PX2_D[3], PX2_D[1], PX2_HACT};
    assign sns2_dn[6:0] =  {PX2_D[10], PX2_D[8], PX2_D[6], PX2_D[4], PX2_D[2], PX2_VACT, PX2_DCLK};
    assign sns2_clkn =      PX2_D[11];  // inout CNVSYNC/TDI
    assign sns2_clkp =      PX2_D[0];  // CNVCLK/TDO
    
    //connect parallel12 sensor to sensor port 3  (all data rotated left by 2 bits
    assign sns3_dp[6:1] =  {PX3_D[8], PX3_D[6], PX3_D[4], PX3_D[2], PX3_D[0], PX3_HACT};
    assign sns3_dn[6:0] =  {PX3_D[9], PX3_D[7], PX3_D[5], PX3_D[3], PX3_D[1], PX3_VACT, PX3_DCLK};
    assign sns3_clkn =      PX3_D[10];  // inout CNVSYNC/TDI
    assign sns3_clkp =      PX3_D[11];  // CNVCLK/TDO
    
    //connect parallel12 sensor to sensor port 4  (all data rotated left by 3 bits
    assign sns4_dp[6:1] =  {PX4_D[5], PX4_D[3], PX4_D[1], PX4_D[11], PX4_D[9], PX4_HACT};
    assign sns4_dn[6:0] =  {PX4_D[6], PX4_D[4], PX4_D[2], PX4_D[0], PX4_D[10], PX4_VACT, PX4_DCLK};
    assign sns4_clkn =      PX4_D[7];  // inout CNVSYNC/TDI
    assign sns4_clkp =      PX4_D[8];  // CNVCLK/TDO
`endif
`endif



    wire [ 9:0] gpio_pins; // inout[9:0] ([6]-synco0,[7]-syncio0,[8]-synco1,[9]-syncio1)
// Connect trigger outs to triggets in (#10 needed for Icarus)
assign #10 gpio_pins[7] = gpio_pins[6];
assign #10 gpio_pins[9] = gpio_pins[8];

  // DDR3 signals
    wire        SDRST;
    wire        SDCLK;  // output
    wire        SDNCLK; // output
    wire [ADDRESS_NUMBER-1:0] SDA;    // output[14:0] 
    wire [ 2:0] SDBA;   // output[2:0] 
    wire        SDWE;   // output
    wire        SDRAS;  // output
    wire        SDCAS;  // output
    wire        SDCKE;  // output
    wire        SDODT;  // output
    wire [15:0] SDD;    // inout[15:0] 
    wire        SDDML;  // inout
    wire        DQSL;   // inout
    wire        NDQSL;  // inout
    wire        SDDMU;  // inout
    wire        DQSU;   // inout
    wire        NDQSU;  // inout
    wire        memclk;

    wire        ffclk0p; // input
    wire        ffclk0n; // input
    wire        ffclk1p; // input
    wire        ffclk1n;  // input


  
// axi_hp simulation signals
    wire HCLK;
    wire [31:0] afi_sim_rd_address;    // output[31:0] 
    wire [ 5:0] afi_sim_rid;           // output[5:0]  SuppressThisWarning VEditor - not used - just view
//  reg         afi_sim_rd_valid;      // input
    wire        afi_sim_rd_valid;      // input
    wire        afi_sim_rd_ready;      // output
//  reg  [63:0] afi_sim_rd_data;       // input[63:0] 
    wire [63:0] afi_sim_rd_data;       // input[63:0] 
    wire [ 2:0] afi_sim_rd_cap;        // output[2:0]  SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] afi_sim_rd_qos;        // output[3:0]  SuppressThisWarning VEditor - not used - just view
    wire  [ 1:0] afi_sim_rd_resp;       // input[1:0] 
//  reg  [ 1:0] afi_sim_rd_resp;       // input[1:0] 

    wire [31:0] afi_sim_wr_address;    // output[31:0] SuppressThisWarning VEditor - not used - just view
    wire [ 5:0] afi_sim_wid;           // output[5:0]  SuppressThisWarning VEditor - not used - just view
    wire        afi_sim_wr_valid;      // output
    wire        afi_sim_wr_ready;      // input
//  reg         afi_sim_wr_ready;      // input
    wire [63:0] afi_sim_wr_data;       // output[63:0] SuppressThisWarning VEditor - not used - just view
    wire [ 7:0] afi_sim_wr_stb;        // output[7:0]  SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] afi_sim_bresp_latency; // input[3:0] 
//  reg  [ 3:0] afi_sim_bresp_latency; // input[3:0] 
    wire [ 2:0] afi_sim_wr_cap;        // output[2:0]  SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] afi_sim_wr_qos;        // output[3:0]  SuppressThisWarning VEditor - not used - just view

    assign HCLK = x393_i.ps7_i.SAXIHP0ACLK; // shortcut name

    wire [31:0] afi1_sim_wr_address;    // output[31:0] SuppressThisWarning VEditor - not used - just view
    wire [ 5:0] afi1_sim_wid;           // output[5:0]  SuppressThisWarning VEditor - not used - just view
    wire        afi1_sim_wr_valid;      // output
    wire        afi1_sim_wr_ready;      // input
//  reg         afi1_sim_wr_ready;      // input
    wire [63:0] afi1_sim_wr_data;       // output[63:0] SuppressThisWarning VEditor - not used - just view
    wire [ 7:0] afi1_sim_wr_stb;        // output[7:0]  SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] afi1_sim_bresp_latency; // input[3:0] 
//  reg  [ 3:0] afi1_sim_bresp_latency; // input[3:0] 
    wire [ 2:0] afi1_sim_wr_cap;        // output[2:0]  SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] afi1_sim_wr_qos;        // output[3:0]  SuppressThisWarning VEditor - not used - just view

    wire [31:0] sim_cmprs0_addr = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h0))?afi1_sim_wr_address:32'bz; // SuppressThisWarning VEditor - not used - just view
    wire [31:0] sim_cmprs1_addr = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h1))?afi1_sim_wr_address:32'bz; // SuppressThisWarning VEditor - not used - just view
    wire [31:0] sim_cmprs2_addr = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h2))?afi1_sim_wr_address:32'bz; // SuppressThisWarning VEditor - not used - just view
    wire [31:0] sim_cmprs3_addr = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h3))?afi1_sim_wr_address:32'bz; // SuppressThisWarning VEditor - not used - just view
    wire [63:0] sim_cmprs0_data = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h0))?afi1_sim_wr_data:64'bz;    // SuppressThisWarning VEditor - not used - just view
    wire [63:0] sim_cmprs1_data = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h1))?afi1_sim_wr_data:64'bz;    // SuppressThisWarning VEditor - not used - just view
    wire [63:0] sim_cmprs2_data = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h2))?afi1_sim_wr_data:64'bz;    // SuppressThisWarning VEditor - not used - just view
    wire [63:0] sim_cmprs3_data = (afi1_sim_wr_valid && afi1_sim_wr_ready && (afi1_sim_wid[1:0] == 2'h3))?afi1_sim_wr_data:64'bz;    // SuppressThisWarning VEditor - not used - just view
//x393_i.ps7_i.SAXIHP1ACLK

    always @ (posedge x393_i.ps7_i.SAXIHP1ACLK) if (afi1_sim_wr_valid && afi1_sim_wr_ready) begin
        if (afi1_sim_wid[1:0] == 2'h0) $display("---sim_cmprs0: %x:%x", afi1_sim_wr_address, afi1_sim_wr_data);
        if (afi1_sim_wid[1:0] == 2'h1) $display("---sim_cmprs1: %x:%x", afi1_sim_wr_address, afi1_sim_wr_data);
        if (afi1_sim_wid[1:0] == 2'h2) $display("---sim_cmprs2: %x:%x", afi1_sim_wr_address, afi1_sim_wr_data);
        if (afi1_sim_wid[1:0] == 2'h3) $display("---sim_cmprs3: %x:%x", afi1_sim_wr_address, afi1_sim_wr_data);
    end
    
// afi loopback (membridge)
    assign #1 afi_sim_rd_data=  afi_sim_rd_ready?{2'h0,afi_sim_rd_address[31:3],1'h1,  2'h0,afi_sim_rd_address[31:3],1'h0}:64'bx;
    assign #1 afi_sim_rd_valid = afi_sim_rd_ready;
    assign #1 afi_sim_rd_resp = afi_sim_rd_ready?2'b0:2'bx;
    assign #1 afi_sim_wr_ready = afi_sim_wr_valid;
    assign #1 afi_sim_bresp_latency=4'h5; 
// afi1 (compressor) loopback
    assign #1 afi1_sim_wr_ready = afi1_sim_wr_valid;
    assign #1 afi1_sim_bresp_latency=4'h5; 


// SAXI_GP0 - histograms to system memory
    wire        SAXI_GP0_CLK; 
    wire [31:0] saxi_gp0_sim_wr_address;    // output[31:0]   SuppressThisWarning VEditor - not used - just view 
    wire [ 5:0] saxi_gp0_sim_wid;           // output[5:0]    SuppressThisWarning VEditor - not used - just view
    wire        saxi_gp0_sim_wr_valid;      // output
    wire        saxi_gp0_sim_wr_ready;      // input
    wire [31:0] saxi_gp0_sim_wr_data;       // output[31:0]   SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] saxi_gp0_sim_wr_stb;        // output[3:0]    SuppressThisWarning VEditor - not used - just view
    wire [ 1:0] saxi_gp0_sim_wr_size;       // output[1:0]    SuppressThisWarning VEditor - not used - just view
    wire [ 3:0] saxi_gp0_sim_bresp_latency; // input[3:0] 
    wire [ 3:0] saxi_gp0_sim_wr_qos;        // output[3:0]    SuppressThisWarning VEditor - not used - just view

    assign SAXI_GP0_CLK = x393_i.ps7_i.SAXIGP0ACLK;
    assign #1 saxi_gp0_sim_wr_ready = saxi_gp0_sim_wr_valid;
    assign #1 saxi_gp0_sim_bresp_latency=4'h5; 


  
// axi_hp register access
  // PS memory mapped registers to read/write over a separate simulation bus running at HCLK, no waits
    reg  [31:0] PS_REG_ADDR;
    reg         PS_REG_WR;
    reg         PS_REG_RD;
    reg         PS_REG_WR1;
    reg         PS_REG_RD1;
    reg  [31:0] PS_REG_DIN;
    wire [31:0] PS_REG_DOUT;
    reg  [31:0] PS_RDATA;  // SuppressThisWarning VEditor - not used - just view
    wire [31:0] PS_REG_DOUT1;
/*  
    reg  [31:0] afi_reg_addr; 
    reg         afi_reg_wr;
    reg         afi_reg_rd;
    reg  [31:0] afi_reg_din;
  wire [31:0] afi_reg_dout;
    reg  [31:0] AFI_REG_RD; // SuppressThisWarning VEditor - not used - just view
*/  
  initial begin
    PS_REG_ADDR <= 'bx;
    PS_REG_WR   <= 0;
    PS_REG_RD   <= 0;
    PS_REG_WR1  <= 0;
    PS_REG_RD1   <= 0;
    PS_REG_DIN  <= 'bx;
    PS_RDATA    <= 'bx;
  end 
  always @ (posedge HCLK) begin
      if      (PS_REG_RD)  PS_RDATA <= PS_REG_DOUT;
      else if (PS_REG_RD1) PS_RDATA <= PS_REG_DOUT1;
  end 
  
    reg [639:0] TEST_TITLE;
  // Simulation signals
    reg [11:0] ARID_IN_r;
    reg [31:0] ARADDR_IN_r;
    reg  [3:0] ARLEN_IN_r;
    reg  [1:0] ARSIZE_IN_r;
    reg  [1:0] ARBURST_IN_r;
    reg [11:0] AWID_IN_r;
    reg [31:0] AWADDR_IN_r;
    reg  [3:0] AWLEN_IN_r;
    reg  [1:0] AWSIZE_IN_r;
    reg  [1:0] AWBURST_IN_r;

    reg [11:0] WID_IN_r;
    reg [31:0] WDATA_IN_r;
    reg [ 3:0] WSTRB_IN_r;
    reg        WLAST_IN_r;
  
    reg [11:0] LAST_ARID; // last issued ARID

  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire [SIMUL_AXI_READ_WIDTH-1:0] SIMUL_AXI_ADDR_W;
  // SuppressWarnings VEditor
    wire        SIMUL_AXI_MISMATCH;
  // SuppressWarnings VEditor
    reg  [31:0] SIMUL_AXI_READ;
  // SuppressWarnings VEditor
    reg  [SIMUL_AXI_READ_WIDTH-1:0] SIMUL_AXI_ADDR;
  // SuppressWarnings VEditor
    reg         SIMUL_AXI_FULL; // some data available
    wire        SIMUL_AXI_EMPTY= ~rvalid && rready && (rid==LAST_ARID); //SuppressThisWarning VEditor : may be unused, just for simulation // use it to wait for?
    reg  [31:0] registered_rdata; // here read data from tasks goes
  // SuppressWarnings VEditor
    reg         WAITING_STATUS;   // tasks are waiting for status

    wire        CLK;
    reg        RST;
    reg        RST_CLEAN  = 1;
    wire [NUM_INTERRUPTS-1:0] IRQ_R =   {x393_i.sata_irq, x393_i.cmprs_irq[3:0], x393_i.frseq_irq[3:0]}; 
    wire [NUM_INTERRUPTS-1:0] IRQ_ACKN;
    wire                [3:0] IRQ_FRSEQ_ACKN = IRQ_ACKN[3:0];
    wire                [3:0] IRQ_CMPRS_ACKN = IRQ_ACKN[7:4];
    wire                      IRQ_SATA_ACKN =  IRQ_ACKN[8];
    reg                 [3:0] IRQ_FRSEQ_DONE = 0;
    reg                 [3:0] IRQ_CMPRS_DONE = 0;
    reg                       IRQ_SATA_DONE =  0;
    wire [NUM_INTERRUPTS-1:0] IRQ_DONE = {IRQ_SATA_DONE, IRQ_CMPRS_DONE, IRQ_FRSEQ_DONE};
    
    reg  [NUM_INTERRUPTS-1:0] IRQ_M =  0; // all disabled - on/off by software
    reg                       IRQ_EN = 1; // handled automatically when accessing MAXI_GP0
    wire                      MAIN_GO;    // main loop can proceed (no INTA)
    wire [NUM_INTERRUPTS-1:0] IRQ_S;      // masked interrupt requests
    wire                      IRQS=|IRQ_S; // at least one interrupt is pending (to yield by main w/o slowing down)
    wire                [3:0] IRQ_FRSEQ_S = IRQ_S[3:0];
    wire                [3:0] IRQ_CMPRS_S = IRQ_S[7:4];
    wire                      IRQ_SATA_S =  IRQ_S[8];
    
    
/*
    sim_soc_interrupts #(
        .NUM_INTERRUPTS(8)
    ) sim_soc_interrupts_i (
        .clk(), // input
        .rst(), // input
        .irq_en(), // input
        .irqm(), // input[7:0] 
        .irq(), // input[7:0] 
        .irq_done(), // input[7:0] 
        .irqs(), // output[7:0] 
        .inta(), // output[7:0] 
        .main_go() // output
    );
*/    
    
        
    reg        AR_SET_CMD_r;
    wire       AR_READY;

    reg        AW_SET_CMD_r;
    wire       AW_READY;

    reg        W_SET_CMD_r;
    wire       W_READY;

    wire [11:0]  #(AXI_TASK_HOLD) ARID_IN = ARID_IN_r;
    wire [31:0]  #(AXI_TASK_HOLD) ARADDR_IN = ARADDR_IN_r;
    wire  [3:0]  #(AXI_TASK_HOLD) ARLEN_IN = ARLEN_IN_r;
    wire  [1:0]  #(AXI_TASK_HOLD) ARSIZE_IN = ARSIZE_IN_r;
    wire  [1:0]  #(AXI_TASK_HOLD) ARBURST_IN = ARBURST_IN_r;
    wire [11:0]  #(AXI_TASK_HOLD) AWID_IN = AWID_IN_r;
    wire [31:0]  #(AXI_TASK_HOLD) AWADDR_IN = AWADDR_IN_r;
    wire  [3:0]  #(AXI_TASK_HOLD) AWLEN_IN = AWLEN_IN_r;
    wire  [1:0]  #(AXI_TASK_HOLD) AWSIZE_IN = AWSIZE_IN_r;
    wire  [1:0]  #(AXI_TASK_HOLD) AWBURST_IN = AWBURST_IN_r;
    wire [11:0]  #(AXI_TASK_HOLD) WID_IN = WID_IN_r;
    wire [31:0]  #(AXI_TASK_HOLD) WDATA_IN = WDATA_IN_r;
    wire [ 3:0]  #(AXI_TASK_HOLD) WSTRB_IN = WSTRB_IN_r;
    wire         #(AXI_TASK_HOLD) WLAST_IN = WLAST_IN_r;
    wire         #(AXI_TASK_HOLD) AR_SET_CMD = AR_SET_CMD_r;
    wire         #(AXI_TASK_HOLD) AW_SET_CMD = AW_SET_CMD_r;
    wire         #(AXI_TASK_HOLD) W_SET_CMD =  W_SET_CMD_r;

    reg  [3:0] RD_LAG;  // ready signal lag in axi read channel (0 - RDY=1, 1..15 - RDY is asserted N cycles after valid)   
    reg  [3:0] B_LAG;   // ready signal lag in axi arete response channel (0 - RDY=1, 1..15 - RDY is asserted N cycles after valid)   

// Simulation modules interconnection
    wire [11:0] arid;
    wire [31:0] araddr;
    wire [3:0]  arlen;
    wire [1:0]  arsize;
    wire [1:0]  arburst;
  // SuppressWarnings VEditor : assigned in $readmem(14) system task
    wire [3:0]  arcache;
  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire [2:0]  arprot;
    wire        arvalid;
    wire        arready;

    wire [11:0] awid;
    wire [31:0] awaddr;
    wire [3:0]  awlen;
    wire [1:0]  awsize;
    wire [1:0]  awburst;
  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire [3:0]  awcache;
  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire [2:0]  awprot;
    wire        awvalid;
    wire        awready;

    wire [11:0] wid;
    wire [31:0] wdata;
    wire [3:0]  wstrb;
    wire        wlast;
    wire        wvalid;
    wire        wready;
  
    wire [31:0] rdata;
  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire [11:0] rid;
    wire        rlast;
  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire  [1:0] rresp;
    wire        rvalid;
    wire        rready;
    wire        rstb=rvalid && rready;

  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire  [1:0] bresp;
  // SuppressWarnings VEditor : assigned in $readmem() system task
    wire [11:0] bid;
    wire        bvalid;
    wire        bready;
    integer     NUM_WORDS_READ;
    integer     NUM_WORDS_EXPECTED;
    reg  [15:0] ENABLED_CHANNELS = 0; // currently enabled memory channels
//  integer     SCANLINE_CUR_X;
//  integer     SCANLINE_CUR_Y;
    wire AXI_RD_EMPTY=NUM_WORDS_READ==NUM_WORDS_EXPECTED; //SuppressThisWarning VEditor : may be unused, just for simulation
  
    reg  [31:0] DEBUG_DATA;
    integer     DEBUG_ADDRESS; 
  
  //NUM_XFER_BITS=6
//  localparam       SCANLINE_PAGES_PER_ROW= (WINDOW_WIDTH>>NUM_XFER_BITS)+((WINDOW_WIDTH[NUM_XFER_BITS-1:0]==0)?0:1);
//  localparam       TILES_PER_ROW= (WINDOW_WIDTH/TILE_WIDTH)+  ((WINDOW_WIDTH % TILE_WIDTH==0)?0:1);
//  localparam       TILE_ROWS_PER_WINDOW= ((WINDOW_HEIGHT-1)/TILE_VSTEP) + 1;
  
//  localparam       TILE_SIZE= TILE_WIDTH*TILE_HEIGHT;
  
  
//  localparam  integer     SCANLINE_FULL_XFER= 1<<NUM_XFER_BITS; // 64 - full page transfer in 8-bursts
//  localparam  integer     SCANLINE_LAST_XFER= WINDOW_WIDTH % (1<<NUM_XFER_BITS); // last page transfer size in a row
  
//  integer ii;
//  integer  SCANLINE_XFER_SIZE;


  initial begin
`ifdef IVERILOG              
    $display("IVERILOG is defined");
`else
    $display("IVERILOG is not defined");
`endif

`ifdef ICARUS              
    $display("ICARUS is defined");
`else
    $display("ICARUS is not defined");
`endif
    $dumpfile(fstname);


  // SuppressWarnings VEditor : assigned in $readmem() system task
    $dumpvars(0,x393_testbench03);
//    CLK =1'b0;
    RST_CLEAN = 1;
    RST = 1'bx;
    AR_SET_CMD_r = 1'b0;
    AW_SET_CMD_r = 1'b0;
    W_SET_CMD_r = 1'b0;
    #500;
//    $display ("x393_i.ddrc_sequencer_i.phy_cmd_i.phy_top_i.rst=%d",x393_i.ddrc_sequencer_i.phy_cmd_i.phy_top_i.rst);
    #500;
    RST = 1'b1;
    NUM_WORDS_EXPECTED =0;
//    #99000; // same as glbl
    #9000; // same as glbl
    repeat (20) @(posedge CLK) ;
    RST =1'b0;
    @(posedge CLK) ;
    RST_CLEAN = 0;
    while (x393_i.mrst) @(posedge CLK) ;
//    repeat (4) @(posedge CLK) ;
//set simulation-only parameters   
    axi_set_b_lag(0); //(1);
    axi_set_rd_lag(0);
// IRQ-related
    IRQ_EN = 1;
    IRQ_M = 0;
    IRQ_FRSEQ_DONE = 0;
    IRQ_CMPRS_DONE = 0;
    IRQ_SATA_DONE =  0;
    
    program_status_all(DEFAULT_STATUS_MODE,'h2a); // mode auto with sequence number increment 

    enable_memcntrl(1);                 // enable memory controller

    set_up;
    axi_set_wbuf_delay(WBUF_DLY_DFLT); //DFLT_WBUF_DELAY - used in synth. code
    
    wait_phase_shifter_ready;
    read_all_status; //stuck here
    
// enable output for address/commands to DDR chip    
    enable_cmda(1);
    repeat (16) @(posedge CLK) ;
// remove reset from DDR chip    
    activate_sdrst(0); // was enabled at system reset

    #5000; // actually 500 usec required
    repeat (16) @(posedge CLK) ;
    enable_cke(1);
    repeat (16) @(posedge CLK) ;
    
//    enable_memcntrl(1);                 // enable memory controller
    enable_memcntrl_channels(16'h0003); // only channel 0 and 1 are enabled
    configure_channel_priority(0,0);    // lowest priority channel 0
    configure_channel_priority(1,0);    // lowest priority channel 1
    enable_reset_ps_pio(1,0);           // enable, no reset

// set MR registers in DDR3 memory, run DCI calibration (long)
    wait_ps_pio_ready(DEFAULT_STATUS_MODE, 1); // wait FIFO not half full 
    schedule_ps_pio ( // schedule software-control memory operation (may need to check FIFO status first)
                        INITIALIZE_OFFSET, // input [9:0] seq_addr; // sequence start address
                        0,                 // input [1:0] page;     // buffer page number
                        0,                 // input       urgent;   // high priority request (only for competition with other channels, will not pass in this FIFO)
                        0,                // input       chn;      // channel buffer to use: 0 - memory read, 1 - memory write
                        `PS_PIO_WAIT_COMPLETE );//  wait_complete; // Do not request a new transaction from the scheduler until previous memory transaction is finished
                        
   
`ifdef WAIT_MRS 
    wait_ps_pio_done(DEFAULT_STATUS_MODE, 1);
`else    
    repeat (32) @(posedge CLK) ;  // what delay is needed to be sure? Add to PS_PIO?
//    first refreshes will be fast (accummulated while waiting)
`endif    
    enable_refresh(1);
    axi_set_dqs_odelay('h78); //??? dafaults - wrong?
    axi_set_dqs_odelay_nominal;
    
    
// ====================== Running optional tests ========================   
    
`ifdef TEST_WRITE_LEVELLING 
    TEST_TITLE = "WRITE_LEVELLING";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_write_levelling;
`endif
`ifdef TEST_READ_PATTERN
    TEST_TITLE = "READ_PATTERN";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_read_pattern;
`endif
`ifdef TEST_WRITE_BLOCK
    TEST_TITLE = "WRITE_BLOCK";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_write_block;
`endif
`ifdef TEST_READ_BLOCK
    TEST_TITLE = "READ_BLOCK";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_read_block;
`endif
`ifdef TESTL_SHORT_SCANLINE
    TEST_TITLE = "TESTL_SHORT_SCANLINE";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_scanline_write(
        1, // valid: 1 or 3 input            [3:0] channel;
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  wait_done;
        1, //WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode
    test_scanline_read (
        1, // valid: 1 or 3 input            [3:0] channel;
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  show_data;
        1, // WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode

    test_scanline_write(
        1, // valid: 1 or 3 input            [3:0] channel;
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  wait_done;
        2, //WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode
    test_scanline_read (
        1, // valid: 1 or 3 input            [3:0] channel;
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  show_data;
        2, // WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode

    test_scanline_write(
        1, // valid: 1 or 3 input            [3:0] channel;
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  wait_done;
        3, //WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode
    test_scanline_read (
        1, // valid: 1 or 3 input            [3:0] channel;
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  show_data;
        3, // WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode



`endif

`ifdef TEST_SCANLINE_WRITE
    TEST_TITLE = "SCANLINE_WRITE";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_scanline_write(
        3, // valid: 1 or 3 input            [3:0] channel; now - 3 only, 1 is for afi
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  wait_done;
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode
        
`endif
`ifdef TEST_SCANLINE_READ
    TEST_TITLE = "SCANLINE_READ";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_scanline_read (
        3, // valid: 1 or 3 input            [3:0] channel; now - 3 only, 1 is for afi
        SCANLINE_EXTRA_PAGES, // input            [1:0] extra_pages;
        1, // input                  show_data;
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        1); // repetitive mode
        
`endif

`ifdef TEST_TILED_WRITE
    TEST_TITLE = "TILED_WRITE";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_tiled_write (
         2,                 // [3:0] channel;
         0,                 //       byte32;
         TILED_KEEP_OPEN,   //       keep_open;
         TILED_EXTRA_PAGES, //       extra_pages;
         1,                //       wait_done;
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        TILE_WIDTH,
        TILE_HEIGHT,
        TILE_VSTEP);
`endif

`ifdef TEST_TILED_READ
    TEST_TITLE = "TILED_READ";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_tiled_read (
        2,                 // [3:0] channel;
        0,                 //       byte32;
        TILED_KEEP_OPEN,   //       keep_open;
        TILED_EXTRA_PAGES, //       extra_pages;
        1,                 //       show_data;
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        TILE_WIDTH,
        TILE_HEIGHT,
        TILE_VSTEP);
         
`endif

`ifdef TEST_TILED_WRITE32
    TEST_TITLE = "TILED_WRITE32";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_tiled_write (
        2, // 4, // 2,                 // [3:0] channel;
        1,                 //       byte32;
        TILED_KEEP_OPEN,   //       keep_open;
        TILED_EXTRA_PAGES, //       extra_pages;
        1,                 //       wait_done;
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        TILE_WIDTH,
        TILE_HEIGHT,
        TILE_VSTEP);
`endif

`ifdef TEST_TILED_READ32
    TEST_TITLE = "TILED_READ32";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_tiled_read (
        2, // 4, //2,                 // [3:0] channel;
        1,                 //       byte32;
        TILED_KEEP_OPEN,   //       keep_open;
        TILED_EXTRA_PAGES, //       extra_pages;
        1,                 //       show_data;
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_X0,
        WINDOW_Y0,
        TILE_WIDTH,
        TILE_HEIGHT,
        TILE_VSTEP);
`endif

`ifdef TEST_AFI_WRITE
    TEST_TITLE = "AFI_WRITE";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_afi_rw (
       1, // write_ddr3;
       SCANLINE_EXTRA_PAGES,//  extra_pages;
       0, //FRAME_START_ADDRESS, //  input [21:0] frame_start_addr;
       FRAME_FULL_WIDTH,    // input [15:0] window_full_width; // 13 bit - in 8*16=128 bit bursts
       'h81, //'h8b,// WINDOW_WIDTH,        // input [15:0] window_width;  // 13 bit - in 8*16=128 bit bursts
       'h2, // WINDOW_HEIGHT,       // input [15:0] window_height; // 16 bit (only 14 are used here)
       'h1, //'h0, // WINDOW_X0,           // input [15:0] window_left;
       'h0, // WINDOW_Y0,           // input [15:0] window_top;
       0,                   // input [28:0] start64;  // relative start address of the transfer (set to 0 when writing lo_addr64)
       AFI_LO_ADDR64,       // input [28:0] lo_addr64; // low address of the system memory range, in 64-bit words 
       AFI_SIZE64,          // input [28:0] size64;    // size of the system memory range in 64-bit words
       0,                  // input        continue;    // 0 start from start64, 1 - continue from where it was
       0, // disable_need
       'h13, //'h3);  // cache_mode;  // 'h3 - normal, 'h13 - debug
       1) // repetitive mode
       
       
`endif


`ifdef TEST_AFI_READ
    TEST_TITLE = "AFI_READ";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    test_afi_rw (
       0, // write_ddr3;
       SCANLINE_EXTRA_PAGES,//  extra_pages;
       0, //FRAME_START_ADDRESS, //  input [21:0] frame_start_addr;
       FRAME_FULL_WIDTH,    // input [15:0] window_full_width; // 13 bit - in 8*16=128 bit bursts
       // Try a single-burst write
       'h81, // 'h8b, // WINDOW_WIDTH,        // input [15:0] window_width;  // 13 bit - in 8*16=128 bit bursts
       'h2, // WINDOW_HEIGHT,       // input [15:0] window_height; // 16 bit (only 14 are used here)
       'h1, // 'h0, // WINDOW_X0,           // input [15:0] window_left;
       'h0, // WINDOW_Y0,           // input [15:0] window_top;
       0,                   // input [28:0] start64;  // relative start address of the transfer (set to 0 when writing lo_addr64)
       AFI_LO_ADDR64,       // input [28:0] lo_addr64; // low address of the system memory range, in 64-bit words 
       AFI_SIZE64,          // input [28:0] size64;    // size of the system memory range in 64-bit words
       0,                  // input        continue;    // 0 start from start64, 1 - continue from where it was
       0, // disable_need
       'h13, //'h3);  // cache_mode;  // 'h3 - normal, 'h13 - debug
       1) // repetitive mode

    $display("===================== #2 TEST_%s =========================",TEST_TITLE);
    test_afi_rw (
       0, // write_ddr3;
       SCANLINE_EXTRA_PAGES,//  extra_pages;
       0, //FRAME_START_ADDRESS, //  input [21:0] frame_start_addr;
       FRAME_FULL_WIDTH,    // input [15:0] window_full_width; // 13 bit - in 8*16=128 bit bursts
       // Try a single-burst read
       'h81, // 'h8b, // WINDOW_WIDTH,        // input [15:0] window_width;  // 13 bit - in 8*16=128 bit bursts
       'h2, // WINDOW_HEIGHT,       // input [15:0] window_height; // 16 bit (only 14 are used here)
       'h1, // 'h0, // WINDOW_X0,           // input [15:0] window_left;
       'h0, // WINDOW_Y0,           // input [15:0] window_top;
       0,                   // input [28:0] start64;  // relative start address of the transfer (set to 0 when writing lo_addr64)
       AFI_LO_ADDR64,       // input [28:0] lo_addr64; // low address of the system memory range, in 64-bit words 
       AFI_SIZE64,          // input [28:0] size64;    // size of the system memory range in 64-bit words
       0,                  // input        continue;    // 0 start from start64, 1 - continue from where it was
       0, // disable_need
       'h13, //'h3);  // cache_mode;  // 'h3 - normal, 'h13 - debug
       1) // repetitive mode
       
`endif

`ifdef USE_FRAME_SEQ_IRQ
    TEST_TITLE = "IRQ FRAME SEQUENCER ENABLE";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    IRQ_M = IRQ_M | 'hf; // all frame sequencer interrupts enabled
// Enable all compressor interrupts
    frame_sequencer_irq_en (0, 1);
    frame_sequencer_irq_en (1, 1);
    frame_sequencer_irq_en (2, 1);
    frame_sequencer_irq_en (3, 1);
    program_status_frame_sequencer(
        3,           // input [1:0] mode;
        0);          // input [5:0] seq_num;
    
`endif


`ifdef TEST_SENSOR

`ifdef DEBUG_RING
    TEST_TITLE = "DEBUG_STATUS";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        program_status_debug (
            3,          // input [1:0] mode;
            0);         // input [5:0] seq_num;
`endif
    TEST_TITLE = "GPIO";
    $display("===================== TEST_%s =========================",TEST_TITLE);

        program_status_gpio (
            3,          // input [1:0] mode;
            0);         // input [5:0] seq_num;

    TEST_TITLE = "RTC";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        program_status_rtc( // also takes snapshot
            3,         // input [1:0] mode;
            0);        //input [5:0] seq_num;
            
        set_rtc (
            32'h12345678, // input [31:0] sec;
            0,            //input [19:0] usec;
            16'h8000);    // input [15:0] corr;  maximal correction to the rtc

//    camsync_setup (
//        4'hf ); // sensor_mask); //
    TEST_TITLE = "RESEST_I2C_SEQUENCER0";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_i2c_command(
            0,   // input                             [1:0] num_sensor;
            1'b1,   // input                                   rst_cmd;    // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
            2'b0,   // input       [SENSI2C_CMD_RUN_PBITS : 0] run_cmd;    // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
            1'b1,   // input                                   set_active; 
            1'b1,   // input                                   active_sda; 
            1'b1);  // input                                   early_release_0;
        set_sensor_i2c_table_reg_wr(
            0,     // input                             [1:0] num_sensor;
            8'h90, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            7'h48, // input                             [6:0] slave_addr; // 7-bit slave address
            8'h0,  // input                             [7:0] rah;        // register address high byte
            4'h3,  // input                             [3:0] num_bytes;  // number of bytes to send
            8'h4); // input                             [7:0] bit_delay;
        set_sensor_i2c_table_reg_rd(
            0,     // input                             [1:0] num_sensor;
            8'h91, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            1'b0,  // input                                   num_bytes_addr; // number of address bytes (0 - 1, 1 - 2)
            3'h2,  // input                             [2:0] num_bytes_rd;  // number of bytes to read, with "0" meaning all 8
            8'h5); // input                             [7:0] bit_delay;

             
    TEST_TITLE = "RESEST_I2C_SEQUENCER1";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_i2c_command(
            1,   // input                             [1:0] num_sensor;
            1'b1,   // input                                   rst_cmd;    // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
            2'b0,   // input       [SENSI2C_CMD_RUN_PBITS : 0] run_cmd;    // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
            1'b1,   // input                                   set_active; 
            1'b0,   // input                                   active_sda; 
            1'b1);  // input                                   early_release_0; 
        set_sensor_i2c_table_reg_wr(
            1,     // input                             [1:0] num_sensor;
            8'h90, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            7'h48, // input                             [6:0] slave_addr; // 7-bit slave address
            8'h12, // input                             [7:0] rah;        // register address high byte
            4'ha,  // input                             [3:0] num_bytes;  // number of bytes to send
            8'h4); // input                             [7:0] bit_delay;
        set_sensor_i2c_table_reg_rd(
            1,     // input                             [1:0] num_sensor;
            8'h91, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            1'b1,  // input                                   num_bytes_addr; // number of address bytes (0 - 1, 1 - 2)
            3'h0,  // input                             [2:0] num_bytes_rd;  // number of bytes to read, with "0" meaning all 8
            8'h4); // input                             [7:0] bit_delay;

    TEST_TITLE = "RESEST_I2C_SEQUENCER2";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_i2c_command(
            2,   // input                             [1:0] num_sensor;
            1'b1,   // input                                   rst_cmd;    // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
            2'b0,   // input       [SENSI2C_CMD_RUN_PBITS : 0] run_cmd;    // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
            1'b1,   // input                                   set_active; 
            1'b1,   // input                                   active_sda; 
            1'b0);  // input                                   early_release_0; 
        set_sensor_i2c_table_reg_wr(
            2,     // input                             [1:0] num_sensor;
            8'h90, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            7'h48, // input                             [6:0] slave_addr; // 7-bit slave address
            8'h34, // input                             [7:0] rah;        // register address high byte
            4'h4,  // input                             [3:0] num_bytes;  // number of bytes to send
            8'h4); // input                             [7:0] bit_delay;
        set_sensor_i2c_table_reg_rd(
            2,     // input                             [1:0] num_sensor;
            8'h91, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            1'b1,  // input                                   num_bytes_addr; // number of address bytes (0 - 1, 1 - 2)
            3'h2,  // input                             [2:0] num_bytes_rd;  // number of bytes to read, with "0" meaning all 8
            8'h4); // input                             [7:0] bit_delay;

    TEST_TITLE = "RESEST_I2C_SEQUENCER3";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_i2c_command(
            3,   // input                             [1:0] num_sensor;
            1'b1,   // input                                   rst_cmd;    // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
            2'b0,   // input       [SENSI2C_CMD_RUN_PBITS : 0] run_cmd;    // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
            1'b1,   // input                                   set_active; 
            1'b0,   // input                                   active_sda; 
            1'b0);  // input                                   early_release_0; 
        set_sensor_i2c_table_reg_wr(
            3,     // input                             [1:0] num_sensor;
            8'h90, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            7'h48, // input                             [6:0] slave_addr; // 7-bit slave address
            8'h0,  // input                             [7:0] rah;        // register address high byte
            4'h2,  // input                             [3:0] num_bytes;  // number of bytes to send
            8'h5); // input                             [7:0] bit_delay;
        set_sensor_i2c_table_reg_rd(
            3,     // input                             [1:0] num_sensor;
            8'h91, // input                             [7:0] page;       // set parameters for 32-bit command with this MSB
            1'b0,  // input                                   num_bytes_addr; // number of address bytes (0 - 1, 1 - 2)
            3'h1,  // input                             [2:0] num_bytes_rd;  // number of bytes to read, with "0" meaning all 8
            8'h5); // input                             [7:0] bit_delay;

    TEST_TITLE = "DELAY_FOR_I2C_RESET";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    
    #1000; // Wait 1 usec
    TEST_TITLE = "TEST_SENSOR1";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    setup_sensor_channel (
        0 ); // input  [1:0] num_sensor;
    
    TEST_TITLE = "TEST_SENSOR2";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    setup_sensor_channel (
    1 ); // input  [1:0] num_sensor;

    TEST_TITLE = "TEST_SENSOR3";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    setup_sensor_channel (
    2 ); // input  [1:0] num_sensor;

    TEST_TITLE = "TEST_SENSOR4";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    setup_sensor_channel (
    3 ); // input  [1:0] num_sensor;

    afi_mux_setup (
        4'hf, // input  [3:0] chn_mask;
        /*
        'h10000000 >> 5,  // input [26:0] afi_cmprs0_sa;   // input [26:0] sa;   // start address in 32-byte chunks
           'h10000 >> 5,  // input [26:0] afi_cmprs0_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        'h10010000 >> 5,  // input [26:0] afi_cmprs1_sa;   // input [26:0] sa;   // start address in 32-byte chunks
           'h10000 >> 5,  // input [26:0] afi_cmprs1_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        'h10020000 >> 5,  // input [26:0] afi_cmprs2_sa;   // input [26:0] sa;   // start address in 32-byte chunks
           'h10000 >> 5,  // input [26:0] afi_cmprs2_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        'h10030000 >> 5,  // input [26:0] afi_cmprs3_sa;   // input [26:0] sa;   // start address in 32-byte chunks
           'h10000 >> 5); // input [26:0] afi_cmprs3_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        */
        'h10000000 >> 5,  // input [26:0] afi_cmprs0_sa;   // input [26:0] sa;   // start address in 32-byte chunks
             'hba0 >> 5,  // 59e/5e0 (exact 2-1) 'h800 >> 5,  // input [26:0] afi_cmprs0_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        'h10010000 >> 5,  // input [26:0] afi_cmprs1_sa;   // input [26:0] sa;   // start address in 32-byte chunks
             'h640>> 5,  // 2f0/320 (exact 2) h400 >> 5,  // input [26:0] afi_cmprs1_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        'h10020000 >> 5,  // input [26:0] afi_cmprs2_sa;   // input [26:0] sa;   // start address in 32-byte chunks
             'h520 >> 5,  // 25e/2a0 (1 less)'h200 >> 5,  // input [26:0] afi_cmprs2_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
        'h10030000 >> 5,  // input [26:0] afi_cmprs3_sa;   // input [26:0] sa;   // start address in 32-byte chunks
             'h460 >> 5); // 1de/ 220 (1 more) 'h100 >> 5); // input [26:0] afi_cmprs3_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
             
    camsync_setup (
        4'hf ); // sensor_mask); //
/*
    TEST_TITLE = "HUFFMAN_LOAD_CHN0";
    $display("===================== TEST_%s =========================",TEST_TITLE);
   program_huffman (0 );
    

    TEST_TITLE = "QUANTIZATION_LOAD_CHN0";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    program_quantization (0);

    TEST_TITLE = "FOCUS_FILTER_LOAD_CHN0";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    program_focus_filt (0);

*/
    TEST_TITLE = "GAMMA_LOAD";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        program_curves(
            0,  //num_sensor,  // input   [1:0] num_sensor;
            0);          // input   [1:0] sub_channel;    
    // just temporarily - enable channel immediately    
//    enable_memcntrl_en_dis(4'hc + {2'b0,num_sensor}, 1);
        program_status_rtc( // also takes snapshot
            3,         // input [1:0] mode;
            0);        //input [5:0] seq_num;
    
`endif

`ifdef USE_CMPRS_IRQ
    TEST_TITLE = "IRQ CMPRS ENABLE";
    $display("===================== TEST_%s =========================",TEST_TITLE);
//    IRQ_FRSEQ_DONE = 0;
    IRQ_M = IRQ_M | 'hf0; // all compressor interrupts enabled, others preserved
//    IRQ_SATA_DONE =  0;
// Enable all compressor interrupts
    compressor_irq_en (0, 1);
    compressor_irq_en (1, 1);
    compressor_irq_en (2, 1);
    compressor_irq_en (3, 1);
    
`endif


`ifdef COMPRESS_SINGLE
  TEST_TITLE = "COMPRESS_FRAME";
  $display("===================== TEST_%s =========================",TEST_TITLE);
//    compressor_run (0, 2); // run single
//    compressor_run (1, 2); // run single
//    compressor_run (2, 2); // run single
//    compressor_run (3, 2); // run single
    compressor_run (0, 3); // run repetitive
    compressor_run (1, 3); // run repetitive
    compressor_run (2, 3); // run repetitive
    compressor_run (3, 3); // run repetitive
`endif

`ifdef READBACK_DELAYS    
  TEST_TITLE = "READBACK";
  $display("===================== TEST_%s =========================",TEST_TITLE);
    axi_get_delays;
`endif

`ifdef TEST_MEMBRIDGE    
  TEST_TITLE = "MEMBRIDGE_READ # 1";
    $display("===================== TEST_%s =========================",TEST_TITLE);
  TEST_TITLE = "MEMBRIDGE READ #1";
  $display("===================== TEST_%s =========================",TEST_TITLE);

  setup_sensor_membridge (0,   // for sensor 0
                          1,  // disable_need
                          0, // read from ddr3
                          1); // repetitive mode
    
  TEST_TITLE = "MEMBRIDGE READ #2";
  $display("===================== TEST_%s =========================",TEST_TITLE);

  setup_sensor_membridge (0,   // for sensor 0
                          1,  // disable_need
                          0,  // read from ddr3
                          0); // single mode
                          
  TEST_TITLE = "MEMBRIDGE_WRITE # 1";
  $display("===================== TEST_%s =========================",TEST_TITLE);

  setup_sensor_membridge (0,   // for sensor 0
                          1,  // disable_need
                          1,  // read from ddr3
                          1); // repetitive mode
    
  TEST_TITLE = "MEMBRIDGE_WRITE # 2";
  $display("===================== TEST_%s =========================",TEST_TITLE);

  setup_sensor_membridge (0,   // for sensor 0
                          1,  // disable_need
                          1,  // read from ddr3
                          0); // single mode
`endif  
    
`ifdef DEBUG_RING
  TEST_TITLE = "READING DEBUG DATA";
  $display("===================== TEST_%s =========================",TEST_TITLE);
    debug_read_ring (32); // read 32 of 32-bit words
`endif
  TEST_TITLE = "ALL_DONE";
  $display("===================== TEST_%s =========================",TEST_TITLE);
  #20000;
        program_status_rtc( // also takes snapshot
            3,         // input [1:0] mode;
            0);        //input [5:0] seq_num;
  TEST_TITLE = "WAITING 80usec more";
  $display("===================== TEST_%s =========================",TEST_TITLE);
  #80000;
`ifdef DEBUG_RING
  TEST_TITLE = "READING DEBUG DATA AGAIN";
  $display("===================== TEST_%s =========================",TEST_TITLE);
    debug_read_ring (32); // read 32 of 32-bit words
`endif    
  $finish;
end
// protect from never end
  initial begin
//       #30000;
//     #200000;
//     #250000;
     #285000;
//      #160000;
//      #175000;
//     #60000;
    $display("finish testbench 2");
  $finish;
  end

// Interrupt actions
task read_compressor_frame_irq;
    input      [1:0] chn;
    output reg [3:0] frame;
    reg        [31:0] rdata;
    begin
        repeat (5) @( posedge CLK);
        read_status_irq(CMPRS_STATUS_REG_BASE + CMPRS_STATUS_REG_INC * chn, rdata);
        @ (posedge CLK) frame = rdata [8 +: 4];
        wait (!CLK);
    end
endtask

task read_compressor_pointer_irq;
    input       [1:0] chn;
    output reg [25:0] pointer;
    reg        [31:0] rdata;
    begin
        repeat (5) @( posedge CLK);
        read_status_irq(CMPRS_AFIMUX_REG_ADDR0 + chn, rdata);
        @ (posedge CLK) pointer = rdata [25:0];
        wait (!CLK);
    end
endtask

task read_sequencer_frame_irq;
    input      [1:0] chn;
    output reg [3:0] frame;
    reg        [31:0] rdata;
    begin
        repeat (5) @( posedge CLK);
        read_status_irq(CMDSEQMUX_STATUS, rdata);
        @ (posedge CLK) frame = rdata [4*chn +: 4];
        wait (!CLK);
    end
endtask


reg   [3:0] IRQ_CMPRS_FRAME_0;
reg   [3:0] IRQ_CMPRS_FRAME_1;
reg   [3:0] IRQ_CMPRS_FRAME_2;
reg   [3:0] IRQ_CMPRS_FRAME_3;
reg   [3:0] IRQ_SEQUENCER_FRAME_0;
reg   [3:0] IRQ_SEQUENCER_FRAME_1;
reg   [3:0] IRQ_SEQUENCER_FRAME_2;
reg   [3:0] IRQ_SEQUENCER_FRAME_3;
reg  [25:0] IRQ_CMPRS_POINTER_0;
reg  [25:0] IRQ_CMPRS_POINTER_1;
reg  [25:0] IRQ_CMPRS_POINTER_2;
reg  [25:0] IRQ_CMPRS_POINTER_3;
//reg   [3:0] IRQ_SEQUENCER_FRAME;
//reg   [3:0] IRQ_CMPRS_FRAME;
//reg  [25:0] IRQ_CMPRS_POINTER;
localparam CHN0 = 0;
localparam CHN1 = 1;
localparam CHN2 = 2;
localparam CHN3 = 3;
always @ (posedge IRQ_CMPRS_ACKN[CHN0]) begin
    // Clear that interrupt
    compressor_irq_clear(CHN0);
    // Read frame pointer
    read_compressor_frame_irq(CHN0, IRQ_CMPRS_FRAME_0);
//    @(posedge CLK) IRQ_CMPRS_FRAME_0 = IRQ_CMPRS_FRAME;
    read_compressor_pointer_irq(CHN0, IRQ_CMPRS_POINTER_0);
//    @(posedge CLK) IRQ_CMPRS_POINTER_0 = IRQ_CMPRS_POINTER;
    // Wait device to remove interrupt
    while (IRQ_CMPRS_S[CHN0]) @ (posedge CLK);
    IRQ_CMPRS_DONE[CHN0] = 1;
    @(posedge CLK) IRQ_CMPRS_DONE[CHN0] = 0;
    $display("Served compressor interrupt channel %d, frame 0x%x, pointer 0x%x (0x%x bytes) @%t",
              CHN0, IRQ_CMPRS_FRAME_0, IRQ_CMPRS_POINTER_0, IRQ_CMPRS_POINTER_0 << 5, $time);
end

always @ (posedge IRQ_CMPRS_ACKN[CHN1]) begin
    // Clear that interrupt
    compressor_irq_clear(CHN1);
    // Read frame pointer
    read_compressor_frame_irq(CHN1, IRQ_CMPRS_FRAME_1);
//    @(posedge CLK) IRQ_CMPRS_FRAME_1 = IRQ_CMPRS_FRAME;
    read_compressor_pointer_irq(CHN1, IRQ_CMPRS_POINTER_1);
//    @(posedge CLK) IRQ_CMPRS_POINTER_1 = IRQ_CMPRS_POINTER;
    // Wait device to remove interrupt
    while (IRQ_CMPRS_S[CHN1]) @ (posedge CLK);
    IRQ_CMPRS_DONE[CHN1] = 1;
    @(posedge CLK) IRQ_CMPRS_DONE[CHN1] = 0;
    $display("Served compressor interrupt channel %d, frame 0x%x, pointer 0x%x (0x%x bytes) @%t",
              CHN1, IRQ_CMPRS_FRAME_1, IRQ_CMPRS_POINTER_1, IRQ_CMPRS_POINTER_1 << 5, $time);
end
always @ (posedge IRQ_CMPRS_ACKN[CHN2]) begin
    // Clear that interrupt
    compressor_irq_clear(CHN2);
    // Read frame pointer
    read_compressor_frame_irq(CHN2, IRQ_CMPRS_FRAME_2);
//    @(posedge CLK) IRQ_CMPRS_FRAME_2 = IRQ_CMPRS_FRAME;
    read_compressor_pointer_irq(CHN2, IRQ_CMPRS_POINTER_2);
//    @(posedge CLK) IRQ_CMPRS_POINTER_2 = IRQ_CMPRS_POINTER;
    // Wait device to remove interrupt
    while (IRQ_CMPRS_S[CHN2]) @ (posedge CLK);
    IRQ_CMPRS_DONE[CHN2] = 1;
    @(posedge CLK) IRQ_CMPRS_DONE[CHN2] = 0;
    $display("Served compressor interrupt channel %d, frame 0x%x, pointer 0x%x (0x%x bytes) @%t",
              CHN2, IRQ_CMPRS_FRAME_2, IRQ_CMPRS_POINTER_2, IRQ_CMPRS_POINTER_2 << 5, $time);
    
end
always @ (posedge IRQ_CMPRS_ACKN[CHN3]) begin
    // Clear that interrupt
    compressor_irq_clear(CHN3);
    // Read frame pointer
    read_compressor_frame_irq(CHN3, IRQ_CMPRS_FRAME_3);
//    @(posedge CLK) IRQ_CMPRS_FRAME_3 = IRQ_CMPRS_FRAME;
    read_compressor_pointer_irq(CHN3, IRQ_CMPRS_POINTER_3);
//    @(posedge CLK) IRQ_CMPRS_POINTER_3 = IRQ_CMPRS_POINTER;
    // Wait device to remove interrupt
    while (IRQ_CMPRS_S[CHN3]) @ (posedge CLK);
    IRQ_CMPRS_DONE[CHN3] = 1;
    @(posedge CLK) IRQ_CMPRS_DONE[CHN3] = 0;
    $display("Served compressor interrupt channel %d, frame 0x%x, pointer 0x%x (0x%x bytes) @%t",
              CHN3, IRQ_CMPRS_FRAME_3, IRQ_CMPRS_POINTER_3, IRQ_CMPRS_POINTER_3 << 5, $time);
end


always @ (posedge IRQ_FRSEQ_ACKN[CHN0]) begin
    // Clear that interrupt
    frame_sequencer_irq_clear(CHN0);
    // Read frame pointer
    read_sequencer_frame_irq(CHN0, IRQ_SEQUENCER_FRAME_0);
//    @(posedge CLK) IRQ_SEQUENCER_FRAME_0 = IRQ_SEQUENCER_FRAME;
    // Wait device to remove interrupt
    while (IRQ_FRSEQ_S[CHN0]) @ (posedge CLK);
    IRQ_FRSEQ_DONE[CHN0] = 1;
    @(posedge CLK) IRQ_FRSEQ_DONE[CHN0] = 0;
    $display("Served frame sequencer interrupt channel %d, frame 0x%x @%t", CHN0, IRQ_SEQUENCER_FRAME_0, $time);
end

always @ (posedge IRQ_FRSEQ_ACKN[CHN1]) begin
    // Clear that interrupt
    frame_sequencer_irq_clear(CHN1);
    // Read frame pointer
    read_sequencer_frame_irq(CHN1, IRQ_SEQUENCER_FRAME_1);
//    @(posedge CLK) IRQ_SEQUENCER_FRAME_1 = IRQ_SEQUENCER_FRAME;
    // Wait device to remove interrupt
    while (IRQ_FRSEQ_S[CHN1]) @ (posedge CLK);
    IRQ_FRSEQ_DONE[CHN1] = 1;
    @(posedge CLK) IRQ_FRSEQ_DONE[CHN1] = 0;
    $display("Served frame sequencer interrupt channel %d, frame 0x%x @%t", CHN1, IRQ_SEQUENCER_FRAME_1, $time);
end

always @ (posedge IRQ_FRSEQ_ACKN[CHN2]) begin
    // Clear that interrupt
    frame_sequencer_irq_clear(CHN2);
    // Read frame pointer
    read_sequencer_frame_irq(CHN2, IRQ_SEQUENCER_FRAME_2);
//    @(posedge CLK) IRQ_SEQUENCER_FRAME_2 = IRQ_SEQUENCER_FRAME;
    // Wait device to remove interrupt
    while (IRQ_FRSEQ_S[CHN2]) @ (posedge CLK);
    IRQ_FRSEQ_DONE[CHN2] = 1;
    @(posedge CLK) IRQ_FRSEQ_DONE[CHN2] = 0;
    $display("Served frame sequencer interrupt channel %d, frame 0x%x @%t", CHN2, IRQ_SEQUENCER_FRAME_2, $time);
end

always @ (posedge IRQ_FRSEQ_ACKN[CHN3]) begin
    // Clear that interrupt
    frame_sequencer_irq_clear(CHN3);
    // Read frame pointer
    read_sequencer_frame_irq(CHN3, IRQ_SEQUENCER_FRAME_3);
//    @(posedge CLK) IRQ_SEQUENCER_FRAME_3 = IRQ_SEQUENCER_FRAME;
    // Wait device to remove interrupt
    while (IRQ_FRSEQ_S[CHN3]) @ (posedge CLK);
    IRQ_FRSEQ_DONE[CHN3] = 1;
    @(posedge CLK) IRQ_FRSEQ_DONE[CHN3] = 0;
    $display("Served frame sequencer interrupt channel %d, frame 0x%x @%t", CHN3, IRQ_SEQUENCER_FRAME_3, $time);
end



assign x393_i.ps7_i.FCLKCLK=        {4{CLK}};
assign x393_i.ps7_i.FCLKRESETN=     {RST,~RST,RST,~RST};
// Read address
assign x393_i.ps7_i.MAXIGP0ARADDR=  araddr;
assign x393_i.ps7_i.MAXIGP0ARVALID= arvalid;
assign arready=                            x393_i.ps7_i.MAXIGP0ARREADY;
assign x393_i.ps7_i.MAXIGP0ARID=    arid; 
assign x393_i.ps7_i.MAXIGP0ARLEN=   arlen;
assign x393_i.ps7_i.MAXIGP0ARSIZE=  arsize[1:0]; // arsize[2] is not used
assign x393_i.ps7_i.MAXIGP0ARBURST= arburst;
// Read data
assign rdata=                              x393_i.ps7_i.MAXIGP0RDATA; 
assign rvalid=                             x393_i.ps7_i.MAXIGP0RVALID;
assign x393_i.ps7_i.MAXIGP0RREADY=  rready;
assign rid=                                x393_i.ps7_i.MAXIGP0RID;
assign rlast=                              x393_i.ps7_i.MAXIGP0RLAST;
assign rresp=                              x393_i.ps7_i.MAXIGP0RRESP;
// Write address
assign x393_i.ps7_i.MAXIGP0AWADDR=  awaddr;
assign x393_i.ps7_i.MAXIGP0AWVALID= awvalid;

assign awready=                            x393_i.ps7_i.MAXIGP0AWREADY;

//assign awready= AWREADY_AAAA;
assign x393_i.ps7_i.MAXIGP0AWID=awid;

      // SuppressWarnings VEditor all
//  wire [ 1:0] AWLOCK;
      // SuppressWarnings VEditor all
//  wire [ 3:0] AWCACHE;
      // SuppressWarnings VEditor all
//  wire [ 2:0] AWPROT;
assign x393_i.ps7_i.MAXIGP0AWLEN=   awlen;
assign x393_i.ps7_i.MAXIGP0AWSIZE=  awsize[1:0]; // awsize[2] is not used
assign x393_i.ps7_i.MAXIGP0AWBURST= awburst;
      // SuppressWarnings VEditor all
//  wire [ 3:0] AWQOS;
// Write data
assign x393_i.ps7_i.MAXIGP0WDATA=   wdata;
assign x393_i.ps7_i.MAXIGP0WVALID=  wvalid;
assign wready=                             x393_i.ps7_i.MAXIGP0WREADY;
assign x393_i.ps7_i.MAXIGP0WID=     wid;
assign x393_i.ps7_i.MAXIGP0WLAST=   wlast;
assign x393_i.ps7_i.MAXIGP0WSTRB=   wstrb;
// Write response
assign bvalid=                             x393_i.ps7_i.MAXIGP0BVALID;
assign x393_i.ps7_i.MAXIGP0BREADY=  bready;
assign bid=                                x393_i.ps7_i.MAXIGP0BID;
assign bresp=                              x393_i.ps7_i.MAXIGP0BRESP;
//TODO: See how to show problems in include files opened in the editor (test all top *.v files that have it)
// Top module under test
    x393 #(
// TODO: Are these parameters needed? They are included in x393 from the save x393_parameters.vh    
        .MCONTR_WR_MASK                    (MCONTR_WR_MASK),
        .MCONTR_RD_MASK                    (MCONTR_RD_MASK),
        .MCONTR_CMD_WR_ADDR                (MCONTR_CMD_WR_ADDR),
        .MCONTR_BUF0_RD_ADDR               (MCONTR_BUF0_RD_ADDR),
        .MCONTR_BUF0_WR_ADDR               (MCONTR_BUF0_WR_ADDR),
        .MCONTR_BUF2_RD_ADDR               (MCONTR_BUF2_RD_ADDR),
        .MCONTR_BUF2_WR_ADDR               (MCONTR_BUF2_WR_ADDR),
        .MCONTR_BUF3_RD_ADDR               (MCONTR_BUF3_RD_ADDR),
        .MCONTR_BUF3_WR_ADDR               (MCONTR_BUF3_WR_ADDR),
        .MCONTR_BUF4_RD_ADDR               (MCONTR_BUF4_RD_ADDR),
        .MCONTR_BUF4_WR_ADDR               (MCONTR_BUF4_WR_ADDR),
        .CONTROL_ADDR                      (CONTROL_ADDR),
        .CONTROL_ADDR_MASK                 (CONTROL_ADDR_MASK),
        .STATUS_ADDR                       (STATUS_ADDR),
        .STATUS_ADDR_MASK                  (STATUS_ADDR_MASK),
        .AXI_WR_ADDR_BITS                  (AXI_WR_ADDR_BITS),
        .AXI_RD_ADDR_BITS                  (AXI_RD_ADDR_BITS),
        .STATUS_DEPTH                      (STATUS_DEPTH),
        .DLY_LD                            (DLY_LD),
        .DLY_LD_MASK                       (DLY_LD_MASK),
        .MCONTR_PHY_0BIT_ADDR              (MCONTR_PHY_0BIT_ADDR),
        .MCONTR_PHY_0BIT_ADDR_MASK         (MCONTR_PHY_0BIT_ADDR_MASK),
        .MCONTR_PHY_0BIT_DLY_SET           (MCONTR_PHY_0BIT_DLY_SET),
        .MCONTR_PHY_0BIT_CMDA_EN           (MCONTR_PHY_0BIT_CMDA_EN),
        .MCONTR_PHY_0BIT_SDRST_ACT         (MCONTR_PHY_0BIT_SDRST_ACT),
        .MCONTR_PHY_0BIT_CKE_EN            (MCONTR_PHY_0BIT_CKE_EN),
        .MCONTR_PHY_0BIT_DCI_RST           (MCONTR_PHY_0BIT_DCI_RST),
        .MCONTR_PHY_0BIT_DLY_RST           (MCONTR_PHY_0BIT_DLY_RST),
        .MCONTR_TOP_0BIT_ADDR              (MCONTR_TOP_0BIT_ADDR),
        .MCONTR_TOP_0BIT_ADDR_MASK         (MCONTR_TOP_0BIT_ADDR_MASK),
        .MCONTR_TOP_0BIT_MCONTR_EN         (MCONTR_TOP_0BIT_MCONTR_EN),
        .MCONTR_TOP_0BIT_REFRESH_EN        (MCONTR_TOP_0BIT_REFRESH_EN),
        .MCONTR_PHY_16BIT_ADDR             (MCONTR_PHY_16BIT_ADDR),
        .MCONTR_PHY_16BIT_ADDR_MASK        (MCONTR_PHY_16BIT_ADDR_MASK),
        .MCONTR_PHY_16BIT_PATTERNS         (MCONTR_PHY_16BIT_PATTERNS),
        .MCONTR_PHY_16BIT_PATTERNS_TRI     (MCONTR_PHY_16BIT_PATTERNS_TRI),
        .MCONTR_PHY_16BIT_WBUF_DELAY       (MCONTR_PHY_16BIT_WBUF_DELAY),
        .MCONTR_PHY_16BIT_EXTRA            (MCONTR_PHY_16BIT_EXTRA),
        .MCONTR_PHY_STATUS_CNTRL           (MCONTR_PHY_STATUS_CNTRL),
        .MCONTR_ARBIT_ADDR                 (MCONTR_ARBIT_ADDR),
        .MCONTR_ARBIT_ADDR_MASK            (MCONTR_ARBIT_ADDR_MASK),
        .MCONTR_TOP_16BIT_ADDR             (MCONTR_TOP_16BIT_ADDR),
        .MCONTR_TOP_16BIT_ADDR_MASK        (MCONTR_TOP_16BIT_ADDR_MASK),
        .MCONTR_TOP_16BIT_CHN_EN           (MCONTR_TOP_16BIT_CHN_EN),
        .MCONTR_TOP_16BIT_REFRESH_PERIOD   (MCONTR_TOP_16BIT_REFRESH_PERIOD),
        .MCONTR_TOP_16BIT_REFRESH_ADDRESS  (MCONTR_TOP_16BIT_REFRESH_ADDRESS),
        .MCONTR_TOP_16BIT_STATUS_CNTRL     (MCONTR_TOP_16BIT_STATUS_CNTRL),
        .MCONTR_PHY_STATUS_REG_ADDR        (MCONTR_PHY_STATUS_REG_ADDR),
        .MCONTR_TOP_STATUS_REG_ADDR        (MCONTR_TOP_STATUS_REG_ADDR),
        .CHNBUF_READ_LATENCY               (CHNBUF_READ_LATENCY),
        .DFLT_DQS_PATTERN                  (DFLT_DQS_PATTERN),
        .DFLT_DQM_PATTERN                  (DFLT_DQM_PATTERN),
        .DFLT_DQ_TRI_ON_PATTERN            (DFLT_DQ_TRI_ON_PATTERN),
        .DFLT_DQ_TRI_OFF_PATTERN           (DFLT_DQ_TRI_OFF_PATTERN),
        .DFLT_DQS_TRI_ON_PATTERN           (DFLT_DQS_TRI_ON_PATTERN),
        .DFLT_DQS_TRI_OFF_PATTERN          (DFLT_DQS_TRI_OFF_PATTERN),
        .DFLT_WBUF_DELAY                   (DFLT_WBUF_DELAY),
        .DFLT_INV_CLK_DIV                  (DFLT_INV_CLK_DIV),
        .DFLT_CHN_EN                       (DFLT_CHN_EN),
        .DFLT_REFRESH_ADDR                 (DFLT_REFRESH_ADDR),
        .DFLT_REFRESH_PERIOD               (DFLT_REFRESH_PERIOD),
        .ADDRESS_NUMBER                    (ADDRESS_NUMBER),
        .COLADDR_NUMBER                    (COLADDR_NUMBER),
        .PHASE_WIDTH                       (PHASE_WIDTH),
        .SLEW_DQ                           (SLEW_DQ),
        .SLEW_DQS                          (SLEW_DQS),
        .SLEW_CMDA                         (SLEW_CMDA),
        .SLEW_CLK                          (SLEW_CLK),
        .IBUF_LOW_PWR                      (IBUF_LOW_PWR),
        .REFCLK_FREQUENCY                  (REFCLK_FREQUENCY),
        .HIGH_PERFORMANCE_MODE             (HIGH_PERFORMANCE_MODE),
        .CLKIN_PERIOD                      (CLKIN_PERIOD),
        .CLKFBOUT_MULT                     (CLKFBOUT_MULT),
        .DIVCLK_DIVIDE                     (DIVCLK_DIVIDE),
        .CLKFBOUT_USE_FINE_PS              (CLKFBOUT_USE_FINE_PS),
        .CLKFBOUT_PHASE                    (CLKFBOUT_PHASE),
        .SDCLK_PHASE                       (SDCLK_PHASE),
        .CLK_PHASE                         (CLK_PHASE),
        .CLK_DIV_PHASE                     (CLK_DIV_PHASE),
        .MCLK_PHASE                        (MCLK_PHASE),
        .REF_JITTER1                       (REF_JITTER1),
        .SS_EN                             (SS_EN),
        .SS_MODE                           (SS_MODE),
        .SS_MOD_PERIOD                     (SS_MOD_PERIOD),
        .CMD_PAUSE_BITS                    (CMD_PAUSE_BITS),
        .CMD_DONE_BIT                      (CMD_DONE_BIT),
        .NUM_CYCLES_LOW_BIT                (NUM_CYCLES_LOW_BIT),
        .NUM_CYCLES_00                     (NUM_CYCLES_00),
        .NUM_CYCLES_01                     (NUM_CYCLES_01),
        .NUM_CYCLES_02                     (NUM_CYCLES_02),
        .NUM_CYCLES_03                     (NUM_CYCLES_03),
        .NUM_CYCLES_04                     (NUM_CYCLES_04),
        .NUM_CYCLES_05                     (NUM_CYCLES_05),
        .NUM_CYCLES_06                     (NUM_CYCLES_06),
        .NUM_CYCLES_07                     (NUM_CYCLES_07),
        .NUM_CYCLES_08                     (NUM_CYCLES_08),
        .NUM_CYCLES_09                     (NUM_CYCLES_09),
        .NUM_CYCLES_10                     (NUM_CYCLES_10),
        .NUM_CYCLES_11                     (NUM_CYCLES_11),
        .NUM_CYCLES_12                     (NUM_CYCLES_12),
        .NUM_CYCLES_13                     (NUM_CYCLES_13),
        .NUM_CYCLES_14                     (NUM_CYCLES_14),
        .NUM_CYCLES_15                     (NUM_CYCLES_15),
        .MCNTRL_PS_ADDR                    (MCNTRL_PS_ADDR),
        .MCNTRL_PS_MASK                    (MCNTRL_PS_MASK),
        .MCNTRL_PS_STATUS_REG_ADDR         (MCNTRL_PS_STATUS_REG_ADDR),
        .MCNTRL_PS_EN_RST                  (MCNTRL_PS_EN_RST),
        .MCNTRL_PS_CMD                     (MCNTRL_PS_CMD),
        .MCNTRL_PS_STATUS_CNTRL            (MCNTRL_PS_STATUS_CNTRL),
        .NUM_XFER_BITS                     (NUM_XFER_BITS),
        .FRAME_WIDTH_BITS                  (FRAME_WIDTH_BITS),
        .FRAME_HEIGHT_BITS                 (FRAME_HEIGHT_BITS),
        .MCNTRL_SCANLINE_CHN1_ADDR         (MCNTRL_SCANLINE_CHN1_ADDR),
        .MCNTRL_SCANLINE_CHN3_ADDR         (MCNTRL_SCANLINE_CHN3_ADDR),
        .MCNTRL_SCANLINE_MASK              (MCNTRL_SCANLINE_MASK),
        .MCNTRL_SCANLINE_MODE              (MCNTRL_SCANLINE_MODE),
        .MCNTRL_SCANLINE_STATUS_CNTRL      (MCNTRL_SCANLINE_STATUS_CNTRL),
        .MCNTRL_SCANLINE_STARTADDR         (MCNTRL_SCANLINE_STARTADDR),
        .MCNTRL_SCANLINE_FRAME_FULL_WIDTH  (MCNTRL_SCANLINE_FRAME_FULL_WIDTH),
        .MCNTRL_SCANLINE_WINDOW_WH         (MCNTRL_SCANLINE_WINDOW_WH),
        .MCNTRL_SCANLINE_WINDOW_X0Y0       (MCNTRL_SCANLINE_WINDOW_X0Y0),
        .MCNTRL_SCANLINE_WINDOW_STARTXY    (MCNTRL_SCANLINE_WINDOW_STARTXY),
        .MCNTRL_SCANLINE_STATUS_REG_CHN1_ADDR   (MCNTRL_SCANLINE_STATUS_REG_CHN1_ADDR),
        .MCNTRL_SCANLINE_STATUS_REG_CHN3_ADDR   (MCNTRL_SCANLINE_STATUS_REG_CHN3_ADDR),
        .MCNTRL_SCANLINE_PENDING_CNTR_BITS (MCNTRL_SCANLINE_PENDING_CNTR_BITS),
        .MCNTRL_SCANLINE_FRAME_PAGE_RESET  (MCNTRL_SCANLINE_FRAME_PAGE_RESET),
        .MAX_TILE_WIDTH                    (MAX_TILE_WIDTH),
        .MAX_TILE_HEIGHT                   (MAX_TILE_HEIGHT),
        .MCNTRL_TILED_CHN2_ADDR            (MCNTRL_TILED_CHN2_ADDR),
        .MCNTRL_TILED_CHN4_ADDR            (MCNTRL_TILED_CHN4_ADDR),
        .MCNTRL_TILED_MASK                 (MCNTRL_TILED_MASK),
        .MCNTRL_TILED_MODE                 (MCNTRL_TILED_MODE),
        .MCNTRL_TILED_STATUS_CNTRL         (MCNTRL_TILED_STATUS_CNTRL),
        .MCNTRL_TILED_STARTADDR            (MCNTRL_TILED_STARTADDR),
        .MCNTRL_TILED_FRAME_FULL_WIDTH     (MCNTRL_TILED_FRAME_FULL_WIDTH),
        .MCNTRL_TILED_WINDOW_WH            (MCNTRL_TILED_WINDOW_WH),
        .MCNTRL_TILED_WINDOW_X0Y0          (MCNTRL_TILED_WINDOW_X0Y0),
        .MCNTRL_TILED_WINDOW_STARTXY       (MCNTRL_TILED_WINDOW_STARTXY),
        .MCNTRL_TILED_TILE_WHS             (MCNTRL_TILED_TILE_WHS),
        .MCNTRL_TILED_STATUS_REG_CHN2_ADDR (MCNTRL_TILED_STATUS_REG_CHN2_ADDR),
        .MCNTRL_TILED_STATUS_REG_CHN4_ADDR (MCNTRL_TILED_STATUS_REG_CHN4_ADDR),
        .MCNTRL_TILED_PENDING_CNTR_BITS    (MCNTRL_TILED_PENDING_CNTR_BITS),
        .MCNTRL_TILED_FRAME_PAGE_RESET     (MCNTRL_TILED_FRAME_PAGE_RESET),
        .BUFFER_DEPTH32                    (BUFFER_DEPTH32),
        .MCNTRL_TEST01_ADDR                 (MCNTRL_TEST01_ADDR),
        .MCNTRL_TEST01_MASK                 (MCNTRL_TEST01_MASK),
        .MCNTRL_TEST01_CHN1_MODE            (MCNTRL_TEST01_CHN1_MODE),
        .MCNTRL_TEST01_CHN1_STATUS_CNTRL    (MCNTRL_TEST01_CHN1_STATUS_CNTRL),
        .MCNTRL_TEST01_CHN2_MODE            (MCNTRL_TEST01_CHN2_MODE),
        .MCNTRL_TEST01_CHN2_STATUS_CNTRL    (MCNTRL_TEST01_CHN2_STATUS_CNTRL),
        .MCNTRL_TEST01_CHN3_MODE            (MCNTRL_TEST01_CHN3_MODE),
        .MCNTRL_TEST01_CHN3_STATUS_CNTRL    (MCNTRL_TEST01_CHN3_STATUS_CNTRL),
        .MCNTRL_TEST01_CHN4_MODE            (MCNTRL_TEST01_CHN4_MODE),
        .MCNTRL_TEST01_CHN4_STATUS_CNTRL    (MCNTRL_TEST01_CHN4_STATUS_CNTRL),
        .MCNTRL_TEST01_STATUS_REG_CHN1_ADDR (MCNTRL_TEST01_STATUS_REG_CHN1_ADDR),
        .MCNTRL_TEST01_STATUS_REG_CHN2_ADDR (MCNTRL_TEST01_STATUS_REG_CHN2_ADDR),
        .MCNTRL_TEST01_STATUS_REG_CHN3_ADDR (MCNTRL_TEST01_STATUS_REG_CHN3_ADDR),
        .MCNTRL_TEST01_STATUS_REG_CHN4_ADDR (MCNTRL_TEST01_STATUS_REG_CHN4_ADDR)
    ) x393_i (
`ifdef HISPI
        .sns1_dp   (sns1_dp[3:0]),    // inout[3:0]
        .sns1_dn   (sns1_dn[3:0]),    // inout[3:0]
        .sns1_dp74 (sns1_dp[7:4]),    // inout[3:0]
        .sns1_dn74 (sns1_dn[7:4]),    // inout[3:0]
`else    
        .sns1_dp   (sns1_dp),    // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
        .sns1_dn   (sns1_dn),    // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
`endif        
        .sns1_clkp (sns1_clkp),  // inout       CNVCLK/TDO
        .sns1_clkn (sns1_clkn),  // inout       CNVSYNC/TDI
        .sns1_scl  (sns1_scl),   // inout       PX_SCL
        .sns1_sda  (sns1_sda),   // inout       PX_SDA
        .sns1_ctl  (sns1_ctl),   // inout       PX_ARO/TCK
        .sns1_pg   (sns1_pg),    // inout       SENSPGM
        
`ifdef HISPI
        .sns2_dp   (sns2_dp[3:0]),    // inout[3:0]
        .sns2_dn   (sns2_dn[3:0]),    // inout[3:0]
        .sns2_dp74 (sns2_dp[7:4]),    // inout[3:0]
        .sns2_dn74 (sns2_dn[7:4]),    // inout[3:0]
`else    
//        .sns2_dp   (sns1_dp),    // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
//        .sns2_dn   (sns1_dn),    // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
        .sns2_dp   (sns2_dp),    // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
        .sns2_dn   (sns2_dn),    // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
`endif        
        .sns2_clkp (sns2_clkp),  // inout       CNVCLK/TDO
        .sns2_clkn (sns2_clkn),  // inout       CNVSYNC/TDI
        .sns2_scl  (sns2_scl),   // inout       PX_SCL
        .sns2_sda  (sns2_sda),   // inout       PX_SDA
        .sns2_ctl  (sns2_ctl),   // inout       PX_ARO/TCK
        .sns2_pg   (sns2_pg),    // inout       SENSPGM
        
`ifdef HISPI
        .sns3_dp   (sns3_dp[3:0]),    // inout[3:0]
        .sns3_dn   (sns3_dn[3:0]),    // inout[3:0]
        .sns3_dp74 (sns3_dp[7:4]),    // inout[3:0]
        .sns3_dn74 (sns3_dn[7:4]),    // inout[3:0]
`else    
        .sns3_dp   (sns3_dp),    // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
        .sns3_dn   (sns3_dn),    // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
`endif        
        .sns3_clkp (sns3_clkp),  // inout       CNVCLK/TDO
        .sns3_clkn (sns3_clkn),  // inout       CNVSYNC/TDI
        .sns3_scl  (sns3_scl),   // inout       PX_SCL
        .sns3_sda  (sns3_sda),   // inout       PX_SDA
        .sns3_ctl  (sns3_ctl),   // inout       PX_ARO/TCK
        .sns3_pg   (sns3_pg),    // inout       SENSPGM
        
`ifdef HISPI
        .sns4_dp   (sns4_dp[3:0]),    // inout[3:0]
        .sns4_dn   (sns4_dn[3:0]),    // inout[3:0]
        .sns4_dp74 (sns4_dp[7:4]),    // inout[3:0]
        .sns4_dn74 (sns4_dn[7:4]),    // inout[3:0]
`else    
        .sns4_dp   (sns4_dp),    // inout[7:0] {PX_MRST, PXD8, PXD6, PXD4, PXD2, PXD0, PX_HACT, PX_DCLK}
        .sns4_dn   (sns4_dn),    // inout[7:0] {PX_ARST, PXD9, PXD7, PXD5, PXD3, PXD1, PX_VACT, PX_BPF}
`endif        
        .sns4_clkp (sns4_clkp),  // inout       CNVCLK/TDO
        .sns4_clkn (sns4_clkn),  // inout       CNVSYNC/TDI
        .sns4_scl  (sns4_scl),   // inout       PX_SCL
        .sns4_sda  (sns4_sda),   // inout       PX_SDA
        .sns4_ctl  (sns4_ctl),   // inout       PX_ARO/TCK
        .sns4_pg   (sns4_pg),    // inout       SENSPGM
        
        .gpio_pins (gpio_pins),  // inout[9:0] 
    
        .SDRST   (SDRST),        // DDR3 reset (active low)
        .SDCLK   (SDCLK),        // output 
        .SDNCLK  (SDNCLK),       // outputread_and_wait(BASEADDR_STATUS)
        .SDA     (SDA[14:0]),    // output[14:0] 
        .SDBA    (SDBA[2:0]),    // output[2:0] 
        .SDWE    (SDWE),         // output
        .SDRAS   (SDRAS),        // output
        .SDCAS   (SDCAS),        // output
        .SDCKE   (SDCKE),        // output
        .SDODT   (SDODT),        // output
        .SDD     (SDD[15:0]),    // inout[15:0] 
        .SDDML   (SDDML),        // inout
        .DQSL    (DQSL),         // inout
        .NDQSL   (NDQSL),        // inout
        .SDDMU   (SDDMU),        // inout
        .DQSU    (DQSU),         // inout
        .NDQSU   (NDQSU),        // inout
        .memclk  (memclk),
        .ffclk0p (ffclk0p),      // input
        .ffclk0n (ffclk0n),      // input
        .ffclk1p (ffclk1p),      // input
        .ffclk1n (ffclk1n)         // input
    );
    // just to simplify extra delays in tri-state memory bus - provide output enable
    wire WRAP_MCLK=x393_i.mclk;
    wire [7:0] WRAP_PHY_DQ_TRI=x393_i.mcntrl393_i.memctrl16_i.mcontr_sequencer_i.phy_cmd_i.phy_dq_tri[7:0] ;
    wire [7:0] WRAP_PHY_DQS_TRI=x393_i.mcntrl393_i.memctrl16_i.mcontr_sequencer_i.phy_cmd_i.phy_dqs_tri[7:0] ;    
    //x393_i.mcntrl393_i.mcntrl16_i.mcontr_sequencer_i.phy_cmd_i.phy_dq_tri
    //x393_i.mcntrl393_i.mcntrl16_i.mcontr_sequencer_i.phy_cmd_i.phy_dqs_tri
`define USE_DDR3_WRAP 1    
`ifdef USE_DDR3_WRAP
    ddr3_wrap #(
        .ADDRESS_NUMBER     (ADDRESS_NUMBER),
        .TRISTATE_DELAY_CLK (4'h1), // total 2
        .TRISTATE_DELAY     (0),
        .CLK_DELAY          (1550),
        .CMDA_DELAY         (1550),
        .DQS_IN_DELAY       (3150),
        .DQ_IN_DELAY        (1550),
        .DQS_OUT_DELAY      (1550),
        .DQ_OUT_DELAY       (1550)
    ) ddr3_i (
        .mclk    (WRAP_MCLK), // input
        .dq_tri  ({WRAP_PHY_DQ_TRI[4],WRAP_PHY_DQ_TRI[0]}), // input[1:0] 
        .dqs_tri ({WRAP_PHY_DQS_TRI[4],WRAP_PHY_DQS_TRI[0]}), // input[1:0] 
        .SDRST   (SDRST), 
        .SDCLK   (SDCLK), 
        .SDNCLK  (SDNCLK), 
        .SDCKE   (SDCKE), 
        .SDRAS   (SDRAS), 
        .SDCAS   (SDCAS), 
        .SDWE    (SDWE), 
        .SDDMU   (SDDMU),
        .SDDML   (SDDML),
        .SDBA    (SDBA[2:0]),  
        .SDA     (SDA[ADDRESS_NUMBER-1:0]), 
        .SDD     (SDD[15:0]),  
        .DQSU    (DQSU),
        .NDQSU   (NDQSU),
        .DQSL    (DQSL),
        .NDQSL   (NDQSL),
        .SDODT   (SDODT)          // input 
    );
`else
    ddr3 #(
        .TCK_MIN             (2500), 
        .TJIT_PER            (100),
        .TJIT_CC             (200),
        .TERR_2PER           (147),
        .TERR_3PER           (175),
        .TERR_4PER           (194),
        .TERR_5PER           (209),
        .TERR_6PER           (222),
        .TERR_7PER           (232),
        .TERR_8PER           (241),
        .TERR_9PER           (249),
        .TERR_10PER          (257),
        .TERR_11PER          (263),
        .TERR_12PER          (269),
        .TDS                 (125),
        .TDH                 (150),
        .TDQSQ               (200),
        .TDQSS               (0.25),
        .TDSS                (0.20),
        .TDSH                (0.20),
        .TDQSCK              (400),
        .TQSH                (0.38),
        .TQSL                (0.38),
        .TDIPW               (600),
        .TIPW                (900),
        .TIS                 (350),
        .TIH                 (275),
        .TRAS_MIN            (37500),
        .TRC                 (52500),
        .TRCD                (15000),
        .TRP                 (15000),
        .TXP                 (7500),
        .TCKE                (7500),
        .TAON                (400),
        .TWLS                (325),
        .TWLH                (325),
        .TWLO                (9000),
        .TAA_MIN             (15000),
        .CL_TIME             (15000),
        .TDQSCK_DLLDIS       (400),
        .TRRD                (10000),
        .TFAW                (40000),
        .CL_MIN              (5),
        .CL_MAX              (14),
        .AL_MIN              (0),
        .AL_MAX              (2),
        .WR_MIN              (5),
        .WR_MAX              (16),
        .BL_MIN              (4),
        .BL_MAX              (8),
        .CWL_MIN             (5),
        .CWL_MAX             (10),
        .TCK_MAX             (3300),
        .TCH_AVG_MIN         (0.47),
        .TCL_AVG_MIN         (0.47),
        .TCH_AVG_MAX         (0.53),
        .TCL_AVG_MAX         (0.53),
        .TCH_ABS_MIN         (0.43),
        .TCL_ABS_MIN         (0.43),
        .TCKE_TCK            (3),
        .TAA_MAX             (20000),
        .TQH                 (0.38),
        .TRPRE               (0.90),
        .TRPST               (0.30),
        .TDQSH               (0.45),
        .TDQSL               (0.45),
        .TWPRE               (0.90),
        .TWPST               (0.30),
        .TCCD                (4),
        .TCCD_DG             (2),
        .TRAS_MAX            (60e9),
        .TWR                 (15000),
        .TMRD                (4),
        .TMOD                (15000),
        .TMOD_TCK            (12),
        .TRRD_TCK            (4),
        .TRRD_DG             (3000),
        .TRRD_DG_TCK         (2),
        .TRTP                (7500),
        .TRTP_TCK            (4),
        .TWTR                (7500),
        .TWTR_DG             (3750),
        .TWTR_TCK            (4),
        .TWTR_DG_TCK         (2),
        .TDLLK               (512),
        .TRFC_MIN            (260000),
        .TRFC_MAX            (70200000),
        .TXP_TCK             (3),
        .TXPDLL              (24000),
        .TXPDLL_TCK          (10),
        .TACTPDEN            (1),
        .TPRPDEN             (1),
        .TREFPDEN            (1),
        .TCPDED              (1),
        .TPD_MAX             (70200000),
        .TXPR                (270000),
        .TXPR_TCK            (5),
        .TXS                 (270000),
        .TXS_TCK             (5),
        .TXSDLL              (512),
        .TISXR               (350),
        .TCKSRE              (10000),
        .TCKSRE_TCK          (5),
        .TCKSRX              (10000),
        .TCKSRX_TCK          (5),
        .TCKESR_TCK          (4),
        .TAOF                (0.7),
        .TAONPD              (8500),
        .TAOFPD              (8500),
        .ODTH4               (4),
        .ODTH8               (6),
        .TADC                (0.7),
        .TWLMRD              (40),
        .TWLDQSEN            (25),
        .TWLOE               (2000),
        .DM_BITS             (2),
        .ADDR_BITS           (15),
        .ROW_BITS            (15),
        .COL_BITS            (10),
        .DQ_BITS             (16),
        .DQS_BITS            (2),
        .BA_BITS             (3),
        .MEM_BITS            (10),
        .AP                  (10),
        .BC                  (12),
        .BL_BITS             (3),
        .BO_BITS             (2),
        .CS_BITS             (1),
        .RANKS               (1),
        .RZQ                 (240),
        .PRE_DEF_PAT         (8'hAA),
        .STOP_ON_ERROR       (1),
        .DEBUG               (1),
        .BUS_DELAY           (0),
        .RANDOM_OUT_DELAY    (0),
        .RANDOM_SEED         (31913),
        .RDQSEN_PRE          (2),
        .RDQSEN_PST          (1),
        .RDQS_PRE            (2),
        .RDQS_PST            (1),
        .RDQEN_PRE           (0),
        .RDQEN_PST           (0),
        .WDQS_PRE            (2),
        .WDQS_PST            (1),
        .check_strict_mrbits (1),
        .check_strict_timing (1),
        .feature_pasr        (1),
        .feature_truebl4     (0),
        .feature_odt_hi      (0),
        .PERTCKAVG           (512),
        .LOAD_MODE           (4'b0000),
        .REFRESH             (4'b0001),
        .PRECHARGE           (4'b0010),
        .ACTIVATE            (4'b0011),
        .WRITE               (4'b0100),
        .READ                (4'b0101),
        .ZQ                  (4'b0110),
        .NOP                 (4'b0111),
        .PWR_DOWN            (4'b1000),
        .SELF_REF            (4'b1001),
        .RFF_BITS            (128),
        .RFF_CHUNK           (32),
        .SAME_BANK           (2'd0),
        .DIFF_BANK           (2'd1),
        .DIFF_GROUP          (2'd2),
        .SIMUL_500US         (5),
        .SIMUL_200US         (2)
    ) ddr3_i (
        .rst_n   (SDRST),         // input 
        .ck      (SDCLK),         // input 
        .ck_n    (SDNCLK),        // input 
        .cke     (SDCKE),         // input 
        .cs_n    (1'b0),          // input 
        .ras_n   (SDRAS),         // input 
        .cas_n   (SDCAS),         // input 
        .we_n    (SDWE),          // input 
        .dm_tdqs ({SDDMU,SDDML}), // inout[1:0] 
        .ba      (SDBA[2:0]),     // input[2:0] 
        .addr    (SDA[14:0]),     // input[14:0] 
        .dq      (SDD[15:0]),     // inout[15:0] 
        .dqs     ({DQSU,DQSL}),   // inout[1:0] 
        .dqs_n   ({NDQSU,NDQSL}), // inout[1:0] 
        .tdqs_n  (),              // output[1:0] 
        .odt     (SDODT)          // input 
    );
`endif    
    
// Simulation modules    
simul_axi_master_rdaddr
#(
  .ID_WIDTH(12),
  .ADDRESS_WIDTH(32),
  .LATENCY(AXI_RDADDR_LATENCY),          // minimal delay between inout and output ( 0 - next cycle)
  .DEPTH(8),            // maximal number of commands in FIFO
  .DATA_DELAY(3.5),
  .VALID_DELAY(4.0)
) simul_axi_master_rdaddr_i (
    .clk(CLK),
    .reset(RST),
    .arid_in(ARID_IN[11:0]),
    .araddr_in(ARADDR_IN[31:0]),
    .arlen_in(ARLEN_IN[3:0]),
    .arsize_in(ARSIZE_IN[1:0]),
    .arburst_in(ARBURST_IN[1:0]),
    .arcache_in(4'b0),
    .arprot_in(3'b0), //     .arprot_in(2'b0),
    .arid(arid[11:0]),
    .araddr(araddr[31:0]),
    .arlen(arlen[3:0]),
    .arsize(arsize[1:0]),
    .arburst(arburst[1:0]),
    .arcache(arcache[3:0]),
    .arprot(arprot[2:0]),
    .arvalid(arvalid),
    .arready(arready),
    .set_cmd(AR_SET_CMD),  // latch all other input data at posedge of clock
    .ready(AR_READY)     // command/data FIFO can accept command
);

simul_axi_master_wraddr
#(
  .ID_WIDTH(12),
  .ADDRESS_WIDTH(32),
  .LATENCY(AXI_WRADDR_LATENCY),          // minimal delay between inout and output ( 0 - next cycle)
  .DEPTH(8),            // maximal number of commands in FIFO
  .DATA_DELAY(3.5),
  .VALID_DELAY(4.0)
) simul_axi_master_wraddr_i (
    .clk(CLK),
    .reset(RST),
    .awid_in(AWID_IN[11:0]),
    .awaddr_in(AWADDR_IN[31:0]),
    .awlen_in(AWLEN_IN[3:0]),
    .awsize_in(AWSIZE_IN[1:0]),
    .awburst_in(AWBURST_IN[1:0]),
    .awcache_in(4'b0),
    .awprot_in(3'b0), //.awprot_in(2'b0),
    .awid(awid[11:0]),
    .awaddr(awaddr[31:0]),
    .awlen(awlen[3:0]),
    .awsize(awsize[1:0]),
    .awburst(awburst[1:0]),
    .awcache(awcache[3:0]),
    .awprot(awprot[2:0]),
    .awvalid(awvalid),
    .awready(awready),
    .set_cmd(AW_SET_CMD),  // latch all other input data at posedge of clock
    .ready(AW_READY)     // command/data FIFO can accept command
);

simul_axi_master_wdata
#(
  .ID_WIDTH(12),
  .DATA_WIDTH(32),
  .WSTB_WIDTH(4),
  .LATENCY(AXI_WRDATA_LATENCY),          // minimal delay between inout and output ( 0 - next cycle)
  .DEPTH(8),            // maximal number of commands in FIFO
  .DATA_DELAY(3.2),
  .VALID_DELAY(3.6)
) simul_axi_master_wdata_i (
    .clk(CLK),
    .reset(RST),
    .wid_in(WID_IN[11:0]),
    .wdata_in(WDATA_IN[31:0]),
    .wstrb_in(WSTRB_IN[3:0]),
    .wlast_in(WLAST_IN),
    .wid(wid[11:0]),
    .wdata(wdata[31:0]),
    .wstrb(wstrb[3:0]),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
    .set_cmd(W_SET_CMD),  // latch all other input data at posedge of clock
    .ready(W_READY)        // command/data FIFO can accept command
);

simul_axi_slow_ready simul_axi_slow_ready_read_i(
    .clk(CLK),
    .reset(RST), //input         reset,
    .delay(RD_LAG), //input  [3:0]  delay,
    .valid(rvalid), // input         valid,
    .ready(rready)  //output        ready
    );

simul_axi_slow_ready simul_axi_slow_ready_write_resp_i(
    .clk(CLK),
    .reset(RST), //input         reset,
    .delay(B_LAG), //input  [3:0]  delay,
    .valid(bvalid), // input       ADDRESS_NUMBER+2:0  valid,
    .ready(bready)  //output        ready
    );

simul_axi_read #(
    .ADDRESS_WIDTH(SIMUL_AXI_READ_WIDTH)
  ) simul_axi_read_i(
  .clk(CLK),
  .reset(RST),
  .last(rlast),
  .data_stb(rstb),
  .raddr(ARADDR_IN[SIMUL_AXI_READ_WIDTH+1:2]), 
  .rlen(ARLEN_IN),
  .rcmd(AR_SET_CMD),
  .addr_out(SIMUL_AXI_ADDR_W[SIMUL_AXI_READ_WIDTH-1:0]),
  .burst(),     // burst in progress - just debug
  .err_out());  // data last does not match predicted or FIFO over/under run - just debug


simul_axi_hp_rd #(
        .HP_PORT(0)
    ) simul_axi_hp_rd_i (
        .rst            (RST),                               // input
        .aclk           (x393_i.ps7_i.SAXIHP0ACLK),          // input
        .aresetn        (),                                  // output
        .araddr         (x393_i.ps7_i.SAXIHP0ARADDR[31:0]),  // input[31:0] 
        .arvalid        (x393_i.ps7_i.SAXIHP0ARVALID),       // input
        .arready        (x393_i.ps7_i.SAXIHP0ARREADY),       // output
        .arid           (x393_i.ps7_i.SAXIHP0ARID),          // input[5:0] 
        .arlock         (x393_i.ps7_i.SAXIHP0ARLOCK),        // input[1:0] 
        .arcache        (x393_i.ps7_i.SAXIHP0ARCACHE),       // input[3:0] 
        .arprot         (x393_i.ps7_i.SAXIHP0ARPROT),        // input[2:0] 
        .arlen          (x393_i.ps7_i.SAXIHP0ARLEN),         // input[3:0] 
        .arsize         (x393_i.ps7_i.SAXIHP0ARSIZE),        // input[2:0] 
        .arburst        (x393_i.ps7_i.SAXIHP0ARBURST),       // input[1:0] 
        .arqos          (x393_i.ps7_i.SAXIHP0ARQOS),         // input[3:0] 
        .rdata          (x393_i.ps7_i.SAXIHP0RDATA),         // output[63:0] 
        .rvalid         (x393_i.ps7_i.SAXIHP0RVALID),        // output
        .rready         (x393_i.ps7_i.SAXIHP0RREADY),        // input
        .rid            (x393_i.ps7_i.SAXIHP0RID),           // output[5:0] 
        .rlast          (x393_i.ps7_i.SAXIHP0RLAST),         // output
        .rresp          (x393_i.ps7_i.SAXIHP0RRESP),         // output[1:0] 
        .rcount         (x393_i.ps7_i.SAXIHP0RCOUNT),        // output[7:0] 
        .racount        (x393_i.ps7_i.SAXIHP0RACOUNT),       // output[2:0] 
        .rdissuecap1en  (x393_i.ps7_i.SAXIHP0RDISSUECAP1EN), // input
        .sim_rd_address (afi_sim_rd_address), // output[31:0] 
        .sim_rid        (afi_sim_rid), // output[5:0] 
        .sim_rd_valid   (afi_sim_rd_valid), // input
        .sim_rd_ready   (afi_sim_rd_ready), // output
        .sim_rd_data    (afi_sim_rd_data), // input[63:0] 
        .sim_rd_cap     (afi_sim_rd_cap), // output[2:0] 
        .sim_rd_qos     (afi_sim_rd_qos), // output[3:0] 
        .sim_rd_resp    (afi_sim_rd_resp), // input[1:0] 
        .reg_addr       (PS_REG_ADDR), // input[31:0] 
        .reg_wr         (PS_REG_WR), // input
        .reg_rd         (PS_REG_RD), // input
        .reg_din        (PS_REG_DIN), // input[31:0] 
        .reg_dout       (PS_REG_DOUT) // output[31:0] 
    );

simul_axi_hp_wr #(
        .HP_PORT(0)
    ) simul_axi_hp_wr_i (
        .rst            (RST),                               // input
        .aclk           (x393_i.ps7_i.SAXIHP0ACLK),          // input
        .aresetn        (),                                  // output
        .awaddr         (x393_i.ps7_i.SAXIHP0AWADDR),        // input[31:0] 
        .awvalid        (x393_i.ps7_i.SAXIHP0AWVALID),       // input
        .awready        (x393_i.ps7_i.SAXIHP0AWREADY),       // output
        .awid           (x393_i.ps7_i.SAXIHP0AWID),          // input[5:0] 
        .awlock         (x393_i.ps7_i.SAXIHP0AWLOCK),        // input[1:0] 
        .awcache        (x393_i.ps7_i.SAXIHP0AWCACHE),       // input[3:0] 
        .awprot         (x393_i.ps7_i.SAXIHP0AWPROT),        // input[2:0] 
        .awlen          (x393_i.ps7_i.SAXIHP0AWLEN),         // input[3:0] 
        .awsize         (x393_i.ps7_i.SAXIHP0AWSIZE),        // input[2:0] 
        .awburst        (x393_i.ps7_i.SAXIHP0AWBURST),       // input[1:0] 
        .awqos          (x393_i.ps7_i.SAXIHP0AWQOS),         // input[3:0] 
        .wdata          (x393_i.ps7_i.SAXIHP0WDATA),         // input[63:0] 
        .wvalid         (x393_i.ps7_i.SAXIHP0WVALID),        // input
        .wready         (x393_i.ps7_i.SAXIHP0WREADY),        // output
        .wid            (x393_i.ps7_i.SAXIHP0WID),           // input[5:0] 
        .wlast          (x393_i.ps7_i.SAXIHP0WLAST),         // input
        .wstrb          (x393_i.ps7_i.SAXIHP0WSTRB),         // input[7:0] 
        .bvalid         (x393_i.ps7_i.SAXIHP0BVALID),        // output
        .bready         (x393_i.ps7_i.SAXIHP0BREADY),        // input
        .bid            (x393_i.ps7_i.SAXIHP0BID),           // output[5:0] 
        .bresp          (x393_i.ps7_i.SAXIHP0BRESP),         // output[1:0] 
        .wcount         (x393_i.ps7_i.SAXIHP0WCOUNT),        // output[7:0] 
        .wacount        (x393_i.ps7_i.SAXIHP0WACOUNT),       // output[5:0] 
        .wrissuecap1en  (x393_i.ps7_i.SAXIHP0WRISSUECAP1EN), // input
        .sim_wr_address (afi_sim_wr_address),                // output[31:0] 
        .sim_wid        (afi_sim_wid),                       // output[5:0] 
        .sim_wr_valid   (afi_sim_wr_valid),                  // output
        .sim_wr_ready   (afi_sim_wr_ready),                  // input
        .sim_wr_data    (afi_sim_wr_data),                   // output[63:0] 
        .sim_wr_stb     (afi_sim_wr_stb),                    // output[7:0] 
        .sim_bresp_latency(afi_sim_bresp_latency),           // input[3:0] 
        .sim_wr_cap     (afi_sim_wr_cap),                    // output[2:0] 
        .sim_wr_qos     (afi_sim_wr_qos),                    // output[3:0] 
        .reg_addr       (PS_REG_ADDR),                       // input[31:0] 
        .reg_wr         (PS_REG_WR),                         // input
        .reg_rd         (PS_REG_RD),                         // input
        .reg_din        (PS_REG_DIN),                        // input[31:0] 
        .reg_dout       (PS_REG_DOUT)                        // output[31:0] 
    );
    // afi1 - from compressor 
simul_axi_hp_wr #(
        .HP_PORT(1)
    ) simul_axi_hp1_wr_i (
        .rst            (RST),                               // input
        .aclk           (x393_i.ps7_i.SAXIHP1ACLK),          // input
        .aresetn        (),                                  // output
        .awaddr         (x393_i.ps7_i.SAXIHP1AWADDR),        // input[31:0] 
        .awvalid        (x393_i.ps7_i.SAXIHP1AWVALID),       // input
        .awready        (x393_i.ps7_i.SAXIHP1AWREADY),       // output
        .awid           (x393_i.ps7_i.SAXIHP1AWID),          // input[5:0] 
        .awlock         (x393_i.ps7_i.SAXIHP1AWLOCK),        // input[1:0] 
        .awcache        (x393_i.ps7_i.SAXIHP1AWCACHE),       // input[3:0] 
        .awprot         (x393_i.ps7_i.SAXIHP1AWPROT),        // input[2:0] 
        .awlen          (x393_i.ps7_i.SAXIHP1AWLEN),         // input[3:0] 
        .awsize         (x393_i.ps7_i.SAXIHP1AWSIZE),        // input[2:0] 
        .awburst        (x393_i.ps7_i.SAXIHP1AWBURST),       // input[1:0] 
        .awqos          (x393_i.ps7_i.SAXIHP1AWQOS),         // input[3:0] 
        .wdata          (x393_i.ps7_i.SAXIHP1WDATA),         // input[63:0] 
        .wvalid         (x393_i.ps7_i.SAXIHP1WVALID),        // input
        .wready         (x393_i.ps7_i.SAXIHP1WREADY),        // output
        .wid            (x393_i.ps7_i.SAXIHP1WID),           // input[5:0] 
        .wlast          (x393_i.ps7_i.SAXIHP1WLAST),         // input
        .wstrb          (x393_i.ps7_i.SAXIHP1WSTRB),         // input[7:0] 
        .bvalid         (x393_i.ps7_i.SAXIHP1BVALID),        // output
        .bready         (x393_i.ps7_i.SAXIHP1BREADY),        // input
        .bid            (x393_i.ps7_i.SAXIHP1BID),           // output[5:0] 
        .bresp          (x393_i.ps7_i.SAXIHP1BRESP),         // output[1:0] 
        .wcount         (x393_i.ps7_i.SAXIHP1WCOUNT),        // output[7:0] 
        .wacount        (x393_i.ps7_i.SAXIHP1WACOUNT),       // output[5:0] 
        .wrissuecap1en  (x393_i.ps7_i.SAXIHP1WRISSUECAP1EN), // input
        .sim_wr_address (afi1_sim_wr_address),                // output[31:0] 
        .sim_wid        (afi1_sim_wid),                       // output[5:0] 
        .sim_wr_valid   (afi1_sim_wr_valid),                  // output
        .sim_wr_ready   (afi1_sim_wr_ready),                  // input
        .sim_wr_data    (afi1_sim_wr_data),                   // output[63:0] 
        .sim_wr_stb     (afi1_sim_wr_stb),                    // output[7:0] 
        .sim_bresp_latency(afi1_sim_bresp_latency),           // input[3:0] 
        .sim_wr_cap     (afi1_sim_wr_cap),                    // output[2:0] 
        .sim_wr_qos     (afi1_sim_wr_qos),                    // output[3:0] 
        .reg_addr       (PS_REG_ADDR),                        // input[31:0] 
        .reg_wr         (PS_REG_WR1),                         // input
        .reg_rd         (PS_REG_RD1),                         // input
        .reg_din        (PS_REG_DIN),                         // input[31:0] 
        .reg_dout       (PS_REG_DOUT1)                        // output[31:0] 
    );
    
    // SAXI_GP0 - histograms to system memory
    simul_saxi_gp_wr simul_saxi_gp0_wr_i (
        .rst               (RST),                         // input
        .aclk              (SAXI_GP0_CLK),                // input
        .aresetn           (), // output
        .awaddr            (x393_i.ps7_i.SAXIGP0AWADDR),  // input[31:0] 
        .awvalid           (x393_i.ps7_i.SAXIGP0AWVALID), // input
        .awready           (x393_i.ps7_i.SAXIGP0AWREADY), // output
        .awid              (x393_i.ps7_i.SAXIGP0AWID),    // input[5:0] 
        .awlock            (x393_i.ps7_i.SAXIGP0AWLOCK),  // input[1:0] 
        .awcache           (x393_i.ps7_i.SAXIGP0AWCACHE), // input[3:0] 
        .awprot            (x393_i.ps7_i.SAXIGP0AWPROT),  // input[2:0] 
        .awlen             (x393_i.ps7_i.SAXIGP0AWLEN),   // input[3:0] 
        .awsize            (x393_i.ps7_i.SAXIGP0AWSIZE),  // input[1:0] 
        .awburst           (x393_i.ps7_i.SAXIGP0AWBURST), // input[1:0] 
        .awqos             (x393_i.ps7_i.SAXIGP0AWQOS),   // input[3:0] 
        .wdata             (x393_i.ps7_i.SAXIGP0WDATA),   // input[31:0] 
        .wvalid            (x393_i.ps7_i.SAXIGP0WVALID),  // input
        .wready            (x393_i.ps7_i.SAXIGP0WREADY),  // output
        .wid               (x393_i.ps7_i.SAXIGP0WID),     // input[5:0] 
        .wlast             (x393_i.ps7_i.SAXIGP0WLAST),   // input
        .wstrb             (x393_i.ps7_i.SAXIGP0WSTRB),   // input[3:0] 
        .bvalid            (x393_i.ps7_i.SAXIGP0BVALID),  // output
        .bready            (x393_i.ps7_i.SAXIGP0BREADY),  // input
        .bid               (x393_i.ps7_i.SAXIGP0BID),     // output[5:0] 
        .bresp             (x393_i.ps7_i.SAXIGP0BRESP),   // output[1:0] 
        .sim_wr_address    (saxi_gp0_sim_wr_address),     // output[31:0] 
        .sim_wid           (saxi_gp0_sim_wid),            // output[5:0] 
        .sim_wr_valid      (saxi_gp0_sim_wr_valid),       // output
        .sim_wr_ready      (saxi_gp0_sim_wr_ready),       // input
        .sim_wr_data       (saxi_gp0_sim_wr_data),        // output[31:0] 
        .sim_wr_stb        (saxi_gp0_sim_wr_stb),         // output[3:0] 
        .sim_wr_size       (saxi_gp0_sim_wr_size),        // output[1:0] 
        .sim_bresp_latency (saxi_gp0_sim_bresp_latency),  // input[3:0] 
        .sim_wr_qos        (saxi_gp0_sim_wr_qos)          // output[3:0] 
    );


// Generate all clocks
//always #(CLKIN_PERIOD/2) CLK = ~CLK;
    simul_clk #(
        .CLKIN_PERIOD  (CLKIN_PERIOD),
        .MEMCLK_PERIOD (MEMCLK_PERIOD),
        .FCLK0_PERIOD  (FCLK0_PERIOD),
        .FCLK1_PERIOD  (FCLK1_PERIOD)
    ) simul_clk_i (
        .rst     (1'b0),               // input
        .clk     (CLK),                // output
        .memclk  (memclk),             // output
        .ffclk0  ({ffclk0n, ffclk0p}), // output[1:0] 
        .ffclk1  ({ffclk1n, ffclk1p})  // output[1:0] 
    );

// Testing parallel12 -> HiSPi simulation converter
 `ifdef HISPI   
    par12_hispi_psp4l #(
        .FULL_HEIGHT   (HISPI_FULL_HEIGHT),
        .CLOCK_MPY     (HISPI_CLK_MULT),
        .CLOCK_DIV     (HISPI_CLK_DIV),
        .LANE0_DLY     (1.2), // 1.3), 1.3 not stable with default delays
        .LANE1_DLY     (2.7),
        .LANE2_DLY     (0.2),
        .LANE3_DLY     (1.8),
        .CLK_DLY       (2.3),
        .EMBED_LINES   (HISPI_EMBED_LINES),
        .MSB_FIRST     (HISPI_MSB_FIRST),
        .FIFO_LOGDEPTH (HISPI_FIFO_LOGDEPTH)
    ) par12_hispi_psp4l0_i (
        .pclk    ( PX1_MCLK), // input
        .rst     (!PX1_MRST), // input
        .pxd     (PX1_D),     // input[11:0] 
        .vact    (PX1_VACT), // input
        .hact_in (PX1_HACT), // input
        .lane_p  (PX1_LANE_P), // output[3:0] 
        .lane_n  (PX1_LANE_N), // output[3:0] 
        .clk_p   (PX1_CLK_P), // output
        .clk_n   (PX1_CLK_N) // output
    );

    par12_hispi_psp4l #(
        .FULL_HEIGHT   (HISPI_FULL_HEIGHT),
        .CLOCK_MPY     (HISPI_CLK_MULT),
        .CLOCK_DIV     (HISPI_CLK_DIV),
        .LANE0_DLY     (1.2), // 1.3), 1.3 not stable with default delays
        .LANE1_DLY     (2.7),
        .LANE2_DLY     (0.2),
        .LANE3_DLY     (1.8),
        .CLK_DLY       (2.3),
        .EMBED_LINES   (HISPI_EMBED_LINES),
        .MSB_FIRST     (HISPI_MSB_FIRST),
        .FIFO_LOGDEPTH (HISPI_FIFO_LOGDEPTH)
    ) par12_hispi_psp4l1_i (
        .pclk    ( PX2_MCLK), // input
        .rst     (!PX2_MRST), // input
        .pxd     (PX2_D),     // input[11:0] 
        .vact    (PX2_VACT), // input
        .hact_in (PX2_HACT), // input
        .lane_p  (PX2_LANE_P), // output[3:0] 
        .lane_n  (PX2_LANE_N), // output[3:0] 
        .clk_p   (PX2_CLK_P), // output
        .clk_n   (PX2_CLK_N) // output
    );

    par12_hispi_psp4l #(
        .FULL_HEIGHT   (HISPI_FULL_HEIGHT),
        .CLOCK_MPY     (HISPI_CLK_MULT),
        .CLOCK_DIV     (HISPI_CLK_DIV),
        .LANE0_DLY     (1.2), // 1.3), 1.3 not stable with default delays
        .LANE1_DLY     (2.7),
        .LANE2_DLY     (0.2),
        .LANE3_DLY     (1.8),
        .CLK_DLY       (2.3),
        .EMBED_LINES   (HISPI_EMBED_LINES),
        .MSB_FIRST     (HISPI_MSB_FIRST),
        .FIFO_LOGDEPTH (HISPI_FIFO_LOGDEPTH)
    ) par12_hispi_psp4l2_i (
        .pclk    ( PX3_MCLK), // input
        .rst     (!PX3_MRST), // input
        .pxd     (PX3_D),     // input[11:0] 
        .vact    (PX3_VACT), // input
        .hact_in (PX3_HACT), // input
        .lane_p  (PX3_LANE_P), // output[3:0] 
        .lane_n  (PX3_LANE_N), // output[3:0] 
        .clk_p   (PX3_CLK_P), // output
        .clk_n   (PX3_CLK_N) // output
    );

    par12_hispi_psp4l #(
        .FULL_HEIGHT   (HISPI_FULL_HEIGHT),
        .CLOCK_MPY     (HISPI_CLK_MULT),
        .CLOCK_DIV     (HISPI_CLK_DIV),
        .LANE0_DLY     (1.2), // 1.3), 1.3 not stable with default delays
        .LANE1_DLY     (2.7),
        .LANE2_DLY     (0.2),
        .LANE3_DLY     (1.8),
        .CLK_DLY       (2.3),
        .EMBED_LINES   (HISPI_EMBED_LINES),
        .MSB_FIRST     (HISPI_MSB_FIRST),
        .FIFO_LOGDEPTH (HISPI_FIFO_LOGDEPTH)
    ) par12_hispi_psp4l3_i (
        .pclk    ( PX4_MCLK), // input
        .rst     (!PX4_MRST), // input
        .pxd     (PX4_D),     // input[11:0] 
        .vact    (PX4_VACT), // input
        .hact_in (PX4_HACT), // input
        .lane_p  (PX4_LANE_P), // output[3:0] 
        .lane_n  (PX4_LANE_N), // output[3:0] 
        .clk_p   (PX4_CLK_P), // output
        .clk_n   (PX4_CLK_N) // output
    );
`endif    

    simul_clk_mult_div #(
        .MULTIPLIER (PIX_CLK_MULT),
        .DIVISOR    (PIX_CLK_DIV),
        .SKIP_FIRST (5)
    ) simul_clk_div_mult_pix1_i (
        .clk_in     (PX1_MCLK_PRE), // input
        .en         (1'b1), // input
        .clk_out    (PX1_MCLK) // output
    );

    simul_clk_mult_div #(
        .MULTIPLIER (PIX_CLK_MULT),
        .DIVISOR    (PIX_CLK_DIV),
        .SKIP_FIRST (5)
    ) simul_clk_div_mult_pix2_i (
        .clk_in     (PX2_MCLK_PRE), // input
        .en         (1'b1), // input
        .clk_out    (PX2_MCLK) // output
    );

    simul_clk_mult_div #(
        .MULTIPLIER (PIX_CLK_MULT),
        .DIVISOR    (PIX_CLK_DIV),
        .SKIP_FIRST (5)
    ) simul_clk_div_mult_pix3_i (
        .clk_in     (PX3_MCLK_PRE), // input
        .en         (1'b1), // input
        .clk_out    (PX3_MCLK) // output
    );

    simul_clk_mult_div #(
        .MULTIPLIER (PIX_CLK_MULT),
        .DIVISOR    (PIX_CLK_DIV),
        .SKIP_FIRST (5)
    ) simul_clk_div_mult_pix4_i (
        .clk_in     (PX4_MCLK_PRE), // input
        .en         (1'b1), // input
        .clk_out    (PX4_MCLK) // output
    );

    simul_sensor12bits #(
        .SENSOR_IMAGE_TYPE (SENSOR_IMAGE_TYPE0),
        .lline     (VIRTUAL_WIDTH),     // SENSOR12BITS_LLINE),
        .ncols     (FULL_WIDTH),        // (SENSOR12BITS_NCOLS),
`ifdef PF
        .nrows     (PF_HEIGHT),         // SENSOR12BITS_NROWS),
`else
        .nrows     (FULL_HEIGHT),       // SENSOR12BITS_NROWS),
`endif        
        .nrowb     (BLANK_ROWS_BEFORE), // SENSOR12BITS_NROWB),
        .nrowa     (BLANK_ROWS_AFTER),  // SENSOR12BITS_NROWA),
//        .nAV(24),
        .nbpf      (0), // SENSOR12BITS_NBPF),
        .ngp1      (SENSOR12BITS_NGPL),
        .nVLO      (SENSOR12BITS_NVLO),
        .tMD       (SENSOR12BITS_TMD),
        .tDDO      (SENSOR12BITS_TDDO),
        .tDDO1     (SENSOR12BITS_TDDO1),
        .trigdly   (TRIG_LINES), // SENSOR12BITS_TRIGDLY),
        .ramp      (0), //SENSOR12BITS_RAMP),
        .new_bayer (0) // was 1 SENSOR12BITS_NEW_BAYER)
    ) simul_sensor12bits_i (
        .MCLK  (PX1_MCLK), // input 
        .MRST  (PX1_MRST), // input 
        .ARO   (PX1_ARO),  // input 
        .ARST  (PX1_ARST), // input 
        .OE    (1'b0),     // input output enable active low
        .SCL   (sns1_scl), // input 
        .SDA   (sns1_sda), // inout 
        .OFST  (PX1_OFST), // input 
        .D     (PX1_D),    // output[11:0] 
        .DCLK  (PX1_DCLK), // output 
        .BPF   (),         // output 
        .HACT  (PX1_HACT), // output 
        .VACT  (PX1_VACT), // output 
        .VACT1 () // output 
    );


    simul_sensor12bits #(
        .SENSOR_IMAGE_TYPE (SENSOR_IMAGE_TYPE1),
        .lline     (VIRTUAL_WIDTH),     // SENSOR12BITS_LLINE),
        .ncols     (FULL_WIDTH),        // (SENSOR12BITS_NCOLS),
`ifdef PF
        .nrows     (PF_HEIGHT),         // SENSOR12BITS_NROWS),
`else
        .nrows     (FULL_HEIGHT),       // SENSOR12BITS_NROWS),
`endif        
        .nrowb     (BLANK_ROWS_BEFORE), // SENSOR12BITS_NROWB),
        .nrowa     (BLANK_ROWS_AFTER),  // SENSOR12BITS_NROWA),
//        .nAV(24),
        .nbpf      (0), // SENSOR12BITS_NBPF),
        .ngp1      (SENSOR12BITS_NGPL),
        .nVLO      (SENSOR12BITS_NVLO),
        .tMD       (SENSOR12BITS_TMD),
        .tDDO      (SENSOR12BITS_TDDO),
        .tDDO1     (SENSOR12BITS_TDDO1),
        .trigdly   (TRIG_LINES), // SENSOR12BITS_TRIGDLY),
        .ramp      (0), //SENSOR12BITS_RAMP),
        .new_bayer (0) //SENSOR12BITS_NEW_BAYER) was 1
    ) simul_sensor12bits_2_i (
        .MCLK  (PX2_MCLK), // input 
        .MRST  (PX2_MRST), // input 
        .ARO   (PX2_ARO),  // input 
        .ARST  (PX2_ARST), // input 
        .OE    (1'b0),     // input output enable active low
        .SCL   (sns2_scl), // input 
        .SDA   (sns2_sda), // inout 
        .OFST  (PX2_OFST), // input 
        .D     (PX2_D),    // output[11:0] 
        .DCLK  (PX2_DCLK), // output 
        .BPF   (),         // output 
        .HACT  (PX2_HACT), // output 
        .VACT  (PX2_VACT), // output 
        .VACT1 () // output 
    );

    simul_sensor12bits #(
        .SENSOR_IMAGE_TYPE (SENSOR_IMAGE_TYPE2),
        .lline     (VIRTUAL_WIDTH),     // SENSOR12BITS_LLINE),
        .ncols     (FULL_WIDTH),        // (SENSOR12BITS_NCOLS),
`ifdef PF
        .nrows     (PF_HEIGHT),         // SENSOR12BITS_NROWS),
`else
        .nrows     (FULL_HEIGHT),       // SENSOR12BITS_NROWS),
`endif        
        .nrowb     (BLANK_ROWS_BEFORE), // SENSOR12BITS_NROWB),
        .nrowa     (BLANK_ROWS_AFTER),  // SENSOR12BITS_NROWA),
//        .nAV(24),
        .nbpf      (0), // SENSOR12BITS_NBPF),
        .ngp1      (SENSOR12BITS_NGPL),
        .nVLO      (SENSOR12BITS_NVLO),
        .tMD       (SENSOR12BITS_TMD),
        .tDDO      (SENSOR12BITS_TDDO),
        .tDDO1     (SENSOR12BITS_TDDO1),
        .trigdly   (TRIG_LINES), // SENSOR12BITS_TRIGDLY),
        .ramp      (0), // SENSOR12BITS_RAMP),
        .new_bayer (0)  // was 1SENSOR12BITS_NEW_BAYER)
    ) simul_sensor12bits_3_i (
        .MCLK  (PX3_MCLK), // input 
        .MRST  (PX3_MRST), // input 
        .ARO   (PX3_ARO),  // input 
        .ARST  (PX3_ARST), // input 
        .OE    (1'b0),     // input output enable active low
        .SCL   (sns3_scl), // input 
        .SDA   (sns3_sda), // inout 
        .OFST  (PX3_OFST), // input 
        .D     (PX3_D),    // output[11:0] 
        .DCLK  (PX3_DCLK), // output 
        .BPF   (),         // output 
        .HACT  (PX3_HACT), // output 
        .VACT  (PX3_VACT), // output 
        .VACT1 () // output 
    );

    simul_sensor12bits #(
        .SENSOR_IMAGE_TYPE (SENSOR_IMAGE_TYPE3),
        .lline     (VIRTUAL_WIDTH),     // SENSOR12BITS_LLINE),
        .ncols     (FULL_WIDTH),        // (SENSOR12BITS_NCOLS),
`ifdef PF
        .nrows     (PF_HEIGHT),         // SENSOR12BITS_NROWS),
`else
        .nrows     (FULL_HEIGHT),       // SENSOR12BITS_NROWS),
`endif        
        .nrowb     (BLANK_ROWS_BEFORE), // SENSOR12BITS_NROWB),
        .nrowa     (BLANK_ROWS_AFTER),  // SENSOR12BITS_NROWA),
//        .nAV(24),
        .nbpf      (0), // SENSOR12BITS_NBPF),
        .ngp1      (SENSOR12BITS_NGPL),
        .nVLO      (SENSOR12BITS_NVLO),
        .tMD       (SENSOR12BITS_TMD),
        .tDDO      (SENSOR12BITS_TDDO),
        .tDDO1     (SENSOR12BITS_TDDO1),
        .trigdly   (TRIG_LINES), // SENSOR12BITS_TRIGDLY),
        .ramp      (0),// SENSOR12BITS_RAMP),
        .new_bayer (0) // was 1SENSOR12BITS_NEW_BAYER)
    ) simul_sensor12bits_4_i (
        .MCLK  (PX4_MCLK), // input 
        .MRST  (PX4_MRST), // input 
        .ARO   (PX4_ARO),  // input 
        .ARST  (PX4_ARST), // input 
        .OE    (1'b0),     // input output enable active low
        .SCL   (sns4_scl), // input 
        .SDA   (sns4_sda), // inout 
        .OFST  (PX4_OFST), // input 
        .D     (PX4_D),    // output[11:0] 
        .DCLK  (PX4_DCLK), // output 
        .BPF   (),         // output 
        .HACT  (PX4_HACT), // output 
        .VACT  (PX4_VACT), // output 
        .VACT1 () // output 
    );

    sim_soc_interrupts #(
        .NUM_INTERRUPTS (NUM_INTERRUPTS)
    ) sim_soc_interrupts_i (
        .clk            (CLK),       // input
        .rst            (RST_CLEAN), // input
        .irq_en         (IRQ_EN),    // input
        .irqm           (IRQ_M),     // input[7:0] 
        .irq            (IRQ_R),     // input[7:0] 
        .irq_done       (IRQ_DONE),  // input[7:0] @ clk (>=1 cycle) - reset inta bits 
        .irqs           (IRQ_S),     // output[7:0] 
        .inta           (IRQ_ACKN),  // output[7:0] 
        .main_go        (MAIN_GO)    // output
    );

    
    //  wire [ 3:0] SIMUL_ADD_ADDR; 
    always @ (posedge CLK) begin
        if      (RST) SIMUL_AXI_FULL <=0;
        else if (rstb) SIMUL_AXI_FULL <=1;
        
        if (RST) begin
              NUM_WORDS_READ <= 0;
        end else if (rstb) begin
            NUM_WORDS_READ <= NUM_WORDS_READ + 1; 
        end    
        if (rstb) begin
            SIMUL_AXI_ADDR <= SIMUL_AXI_ADDR_W;
            SIMUL_AXI_READ <= rdata;
`ifdef DEBUG_RD_DATA
        $display (" Read data (addr:data): 0x%x:0x%x @%t",SIMUL_AXI_ADDR_W,rdata,$time);
`endif  
            
        end 
        
    end
    
    
// SuppressWarnings VEditor all - these variables are just for viewing, not used anywhere else
    reg DEBUG1, DEBUG2, DEBUG3;
    reg [11:0] GLOBAL_WRITE_ID=0;
    reg [11:0] GLOBAL_READ_ID=0;
    reg [7:0] target_phase=0; // to compare/wait for phase shifter ready
  
   task set_up;
        begin
// set dq /dqs tristate on/off patterns
            axi_set_tristate_patterns;
// set patterns for DM (always 0) and DQS - always the same (may try different for write lev.)
            axi_set_dqs_dqm_patterns;
// prepare all sequences
            set_all_sequences (1,0); // rsel = 1, wsel=0
// prepare write buffer    
            write_block_buf_chn(0,0,256); // fill block memory (channel, page, number)
// set all delays
//#axi_set_delays - from tables, per-pin
`ifdef SET_PER_PIN_DELAYS
            $display("SET_PER_PIN_DELAYS @ %t",$time);
            axi_set_delays; // set all individual delays, aslo runs axi_set_phase()
`else
            $display("SET COMMON DELAYS @ %t",$time);
            axi_set_same_delays(DLY_DQ_IDELAY,DLY_DQ_ODELAY,DLY_DQS_IDELAY,DLY_DQS_ODELAY,DLY_DM_ODELAY,DLY_CMDA_ODELAY);
// set clock phase relative to DDR clk
            axi_set_phase(DLY_PHASE);
`endif            
            
        end
    endtask

// tasks - when tested - move to includes


task set_all_sequences;
    input rsel;
    input wsel;
        begin
            $display("SET MRS @ %t",$time);    
            set_mrs(1);
            $display("SET REFRESH @ %t",$time);    
            set_refresh(
                T_RFC, // input [ 9:0] t_rfc; // =50 for tCK=2.5ns
                T_REFI); //input [ 7:0] t_refi; // 48/97 for normal, 8 - for simulation
            $display("SET WRITE LEVELING @ %t",$time);    
            set_write_lev(16); // write leveling, 16 times   (full buffer - 128) 
            $display("SET READ PATTERN @ %t",$time);    
            set_read_pattern(8); // 8x2*64 bits, 32x32 bits to read
            $display("SET WRITE BLOCK @ %t",$time);    
            set_write_block(
                3'h5,     // bank
                15'h1234, // row address
                10'h100,   // column address
                wsel
            );
           
            $display("SET READ BLOCK @ %t",$time);    
            set_read_block(
                3'h5,     // bank
                15'h1234, // row address
                10'h100,   // column address
                rsel      // sel
            );
        end
endtask

task write_block_scanline_chn;  // SuppressThisWarning VEditor : may be unused
//    input integer chn; // buffer channel
    input   [3:0] chn; // buffer channel
    input   [1:0] page;
//    input integer num_words; // number of words to write (will be rounded up to multiple of 16)
    input [NUM_XFER_BITS:0] num_bursts; // number of 8-bursts to write (will be rounded up to multiple of 16)
    input integer startX;
    input integer startY;
    reg    [29:0] start_addr;
    integer num_words;
    begin
//        $display("====== write_block_scanline_chn:%d page: %x X=0x%x Y=0x%x num=%d @%t", chn, page, startX, startY,num_words, $time);
        $display("====== write_block_scanline_chn:%d page: %x X=0x%x Y=0x%x num=%d @%t", chn, page, startX, startY,num_bursts, $time);
        case (chn)
            0:  start_addr=MCONTR_BUF0_WR_ADDR + (page << 8);
//            1:  start_addr=MCONTR_BUF1_WR_ADDR + (page << 8);
            2:  start_addr=MCONTR_BUF2_WR_ADDR + (page << 8);
            3:  start_addr=MCONTR_BUF3_WR_ADDR + (page << 8);
            4:  start_addr=MCONTR_BUF4_WR_ADDR + (page << 8);
            default: begin
                $display("**** ERROR: Invalid channel (not 0,2,3,4) for write_block_scanline_chn = %d @%t", chn, $time);
                start_addr = MCONTR_BUF0_WR_ADDR+ (page << 8);
            end
        endcase
        num_words=num_bursts << 2;
        write_block_incremtal (start_addr, num_words, (startX<<2) + (startY<<16)); // 1 of startX is 8x16 bit, 16 bytes or 4 32-bit words
//        write_block_incremtal (start_addr, num_bursts << 2, (startX<<2) + (startY<<16)); // 1 of startX is 8x16 bit, 16 bytes or 4 32-bit words
    end
endtask
// x393_mcntrl (no class)
function [12:0] func_encode_mode_tiled;  // SuppressThisWarning VEditor - not used
    input       skip_too_late;
    input       disable_need;
    input       repetitive;
    input       single;
    input       reset_frame;
    input       byte32; // 32-byte columns (0 - 16-byte columns)
    input       keep_open; // for 8 or less rows - do not close page between accesses
    input [1:0] extra_pages; // number of extra pages that need to stay (not to be overwritten) in the buffer
                             // can be used for overlapping tile read access
    input       write_mem;   // write to memory mode (0 - read from memory)
    input       enable;      // enable requests from this channel ( 0 will let current to finish, but not raise want/need)
    input       chn_reset;       // immediately reset al;l the internal circuitry

    reg  [12:0] rslt;
    begin
        rslt = 0;
        rslt[MCONTR_LINTILE_EN] =                                     ~chn_reset;
        rslt[MCONTR_LINTILE_NRESET] =                                  enable;
        rslt[MCONTR_LINTILE_WRITE] =                                   write_mem;
        rslt[MCONTR_LINTILE_EXTRAPG +: MCONTR_LINTILE_EXTRAPG_BITS] =  extra_pages;
        rslt[MCONTR_LINTILE_KEEP_OPEN] =                               keep_open;
        rslt[MCONTR_LINTILE_BYTE32] =                                  byte32;
        rslt[MCONTR_LINTILE_RST_FRAME] =                               reset_frame;
        rslt[MCONTR_LINTILE_SINGLE] =                                  single;
        rslt[MCONTR_LINTILE_REPEAT] =                                  repetitive;
        rslt[MCONTR_LINTILE_DIS_NEED] =                                disable_need;
        rslt[MCONTR_LINTILE_SKIP_LATE] =                               skip_too_late;
        
//        func_encode_mode_tiled={byte32,keep_open,extra_pages,write_mem,enable,~chn_reset};
        func_encode_mode_tiled = rslt;
    end           
endfunction
// x393_mcntrl (no class)
function [12:0] func_encode_mode_scanline; // SuppressThisWarning VEditor - not used
    input       skip_too_late;
    input       disable_need;
    input       repetitive;
    input       single;
    input       reset_frame;
    input [1:0] extra_pages; // number of extra pages that need to stay (not to be overwritten) in the buffer
                             // can be used for overlapping tile read access
    input       write_mem;   // write to memory mode (0 - read from memory)
    input       enable;      // enable requests from this channel ( 0 will let current to finish, but not raise want/need)
    input       chn_reset;       // immediately reset al;l the internal circuitry
    
    reg  [12:0] rslt;
    begin
        rslt = 0;
        rslt[MCONTR_LINTILE_EN] =                                     ~chn_reset;
        rslt[MCONTR_LINTILE_NRESET] =                                  enable;
        rslt[MCONTR_LINTILE_WRITE] =                                   write_mem;
        rslt[MCONTR_LINTILE_EXTRAPG +: MCONTR_LINTILE_EXTRAPG_BITS] =  extra_pages;
        rslt[MCONTR_LINTILE_RST_FRAME] =                               reset_frame;
        rslt[MCONTR_LINTILE_SINGLE] =                                  single;
        rslt[MCONTR_LINTILE_REPEAT] =                                  repetitive;
        rslt[MCONTR_LINTILE_DIS_NEED] =                                disable_need;
        rslt[MCONTR_LINTILE_SKIP_LATE] =                               skip_too_late;
//        func_encode_mode_scanline={extra_pages,write_mem,enable,~chn_reset};
        func_encode_mode_scanline = rslt;
    end           
endfunction

// Sensor - related tasks and functions

// x393_sens_cmprs.py
task setup_sensor_channel;
    input  [1:0] num_sensor;
    
//    reg          trigger_mode; // 0 - auto, 1 - triggered
//    reg          ext_trigger_mode; // 0 - internal, 1 - external trigger (camsync)
//    reg          external_timestamp; // embed local timestamp, 1 - embed received timestamp
//    reg   [31:0] camsync_period;
    reg   [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
    reg   [31:0] window_width;    // 13 bit - in 8*16=128 bit bursts
    reg   [31:0] window_height;   // 16 bit
    reg   [31:0] window_left;
    reg   [31:0] window_top;
    reg   [31:0] frame_start_address;
    reg   [31:0] frame_start_address_inc;
    reg   [31:0] last_buf_frame;
    reg   [31:0] cmode; // compressor mode
//    reg   [31:0] camsync_delay;
//    reg   [ 3:0] sensor_mask;
    
//    reg   [26:0] afi_cmprs0_sa;
//    reg   [26:0] afi_cmprs0_len;
    
// Setting up a single sensor channel 0, sunchannel 0
// 
    begin
        case (num_sensor)
            2'h0: cmode = SIMULATE_CMPRS_CMODE0;
            2'h1: cmode = SIMULATE_CMPRS_CMODE1;
            2'h2: cmode = SIMULATE_CMPRS_CMODE2;
            2'h3: cmode = SIMULATE_CMPRS_CMODE3;
        endcase
    
        window_height = FULL_HEIGHT;
        window_left = 0;
        window_top = 0;
        window_width =       SENSOR_MEMORY_WIDTH_BURSTS;
        frame_full_width =   SENSOR_MEMORY_FULL_WIDTH_BURSTS;
//        camsync_period =     TRIG_PERIOD;
//        camsync_delay =      CAMSYNC_DELAY;
//        trigger_mode =       TRIGGER_MODE;
//        ext_trigger_mode =   EXT_TRIGGER_MODE;
//        external_timestamp = EXTERNAL_TIMESTAMP;
        frame_start_address = FRAME_START_ADDRESS + num_sensor * FRAME_START_ADDRESS_INC * (LAST_BUF_FRAME + 1);
        frame_start_address_inc = FRAME_START_ADDRESS_INC;
        last_buf_frame =     LAST_BUF_FRAME;
//        sensor_mask =        1 << num_sensor;
        
//        afi_cmprs0_sa =      'h10000000 >> 5;
//        afi_cmprs0_len =     'h10000 >> 5; 

        program_status_sensor_i2c(
            num_sensor,  // input [1:0] num_sensor;
//            3,           // input [1:0] mode; Flooding simulation with high speed (sim) i2c
            1,           // input [1:0] mode;
            0);          // input [5:0] seq_num;
        program_status_sensor_io(
            num_sensor,  // input [1:0] num_sensor;
            3,           // input [1:0] mode;
            0);          // input [5:0] seq_num;

        program_status_compressor(
            num_sensor,  // input [1:0] num_sensor;
            3,           // input [1:0] mode;
            0);          // input [5:0] seq_num;
            
            

    // moved before camsync to have a valid timestamo w/o special waiting            
    TEST_TITLE = "MEMORY_SENSOR";
    $display("===================== TEST_%s =========================",TEST_TITLE);
            
        setup_sensor_memory (
            num_sensor,                    // input  [1:0] num_sensor;
            frame_start_address,           // input [31:0] frame_sa;         // 22-bit frame start address ((3 CA LSBs==0. BA==0)
            frame_start_address_inc,       // input [31:0] frame_sa_inc;     // 22-bit frame start address increment  ((3 CA LSBs==0. BA==0)
            last_buf_frame,                // input [31:0] last_frame_num;   // 16-bit number of the last frame in a buffer
            frame_full_width,              // input [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
            window_width,                  // input [31:0] window_width;     // 13 bit - in 8*16=128 bit bursts
            window_height,                 // input [31:0] window_height;    // 16 bit
            window_left,                   // input [31:0] window_left;
            window_top);                   // input [31:0] window_top;

    // Enable arbitration of sensor-to-memory controller
    enable_memcntrl_en_dis(4'h8 + {2'b0,num_sensor}, 1);
//            write_contol_register(MCONTR_TOP_16BIT_ADDR +  MCONTR_TOP_16BIT_CHN_EN, {16'b0,ENABLED_CHANNELS});
    // Set sensor channel priority - 5 usec bonus to compressor/other channels
    configure_channel_priority(4'h8 + {2'b0,num_sensor}, SENSOR_PRIORITY);    // lowest priority channel 1
    
    compressor_run (num_sensor, 0); // reset compressor
    
    
    
    if (cmode == CMPRS_CBIT_CMODE_JPEG18) begin
        setup_compressor_channel(
            num_sensor,              // sensor channel number (0..3)
            ((num_sensor == 1) || (num_sensor == 3))?  1 : 0, // 0,                       // qbank;    // [6:3] quantization table page - 100% quality
//            (num_sensor[1] ^ num_sensor[0]) ? 1 : 0, // 0,                       // qbank;    // [6:3] quantization table page - 100% quality
    //        1,                       // qbank;    // [6:3] quantization table page - 85%? quality
            1,                       // dc_sub;   // [8:7] subtract DC
            cmode, // CMPRS_CBIT_CMODE_JPEG18, //input [31:0] cmode;   //  [13:9] color mode:
    //        parameter CMPRS_CBIT_CMODE_JPEG18 =   4'h0, // color 4:2:0
    //        parameter CMPRS_CBIT_CMODE_MONO6 =    4'h1, // mono 4:2:0 (6 blocks)
    //        parameter CMPRS_CBIT_CMODE_JP46 =     4'h2, // jp4, 6 blocks, original
    //        parameter CMPRS_CBIT_CMODE_JP46DC =   4'h3, // jp4, 6 blocks, dc -improved
    //        parameter CMPRS_CBIT_CMODE_JPEG20 =   4'h4, // mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
    //        parameter CMPRS_CBIT_CMODE_JP4 =      4'h5, // jp4,  4 blocks, dc-improved
    //        parameter CMPRS_CBIT_CMODE_JP4DC =    4'h6, // jp4,  4 blocks, dc-improved
    //        parameter CMPRS_CBIT_CMODE_JP4DIFF =  4'h7, // jp4,  4 blocks, differential
    //        parameter CMPRS_CBIT_CMODE_JP4DIFFHDR =  4'h8, // jp4,  4 blocks, differential, hdr
    //        parameter CMPRS_CBIT_CMODE_JP4DIFFDIV2 = 4'h9, // jp4,  4 blocks, differential, divide by 2
    //        parameter CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 4'ha, // jp4,  4 blocks, differential, hdr,divide by 2
    //        parameter CMPRS_CBIT_CMODE_MONO1 =    4'hb, // mono JPEG (not yet implemented)
    //        parameter CMPRS_CBIT_CMODE_MONO4 =    4'he, // mono 4 blocks
            1,                      // input [31:0] multi_frame;   // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
            3,  // 0,               // input [31:0] bayer;         // [20:18] // Bayer shift
            0,                      // input [31:0] focus_mode;    // [23:21] Set focus mode
            3,                      // num_macro_cols_m1; // number of macroblock colums minus 1
            1,                      // num_macro_rows_m1; // number of macroblock rows minus 1
            // No shift may break same result as x353?
            0, // make same as JP4, no shift 1,                      // input [31:0] left_margin;       // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
            'h120,                  // input [31:0] colorsat_blue; //color saturation for blue (10 bits) //'h90 for 100%
            'h16c,                  // colorsat_red; //color saturation for red (10 bits)   // 'b6 for 100%
            0);                     // input [31:0] coring;     // coring value
    // TODO: calculate widths correctly!
        setup_compressor_memory (
                num_sensor,                    // input  [1:0] num_sensor;
                frame_start_address,           // input [31:0] frame_sa;         // 22-bit frame start address ((3 CA LSBs==0. BA==0)
                frame_start_address_inc,       // input [31:0] frame_sa_inc;     // 22-bit frame start address increment  ((3 CA LSBs==0. BA==0)
                last_buf_frame,                // input [31:0] last_frame_num;   // 16-bit number of the last frame in a buffer
                frame_full_width,              // input [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
                window_width, //  & ~3,             // input [31:0] window_width;    // 13 bit - in 8*16=128 bit bursts
                window_height & ~15,           // input [31:0] window_height;   // 16 bit
                window_left,                   // input [31:0] window_left;
//                window_top+1,                  // input [31:0] window_top; (to match 20x20 tiles in 353)
                window_top,  // make same as JP4, no shift 1,                // input [31:0] window_top; (to match 20x20 tiles in 353)
                
                1,   // input        byte32;     // == 1? 
                2,   //input [31:0] tile_width; // == 2
                1,  // input [31:0] extra_pages; // 1
                1,
                18, //    reg   [7:0] tile_height;
                16 //    reg   [7:0] tile_vstep;
                ); // disable "need" (yield to sensor channels)
    end else if ((cmode == CMPRS_CBIT_CMODE_JP46) ||
             (cmode == CMPRS_CBIT_CMODE_JP46DC) ||
             (cmode == CMPRS_CBIT_CMODE_JP4) ||
             (cmode == CMPRS_CBIT_CMODE_JP4DC) ||
             (cmode == CMPRS_CBIT_CMODE_JP4DIFF) ||
             (cmode == CMPRS_CBIT_CMODE_JP4DIFFHDR) ||
             (cmode == CMPRS_CBIT_CMODE_JP4DIFFDIV2) ||
             (cmode == CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2)) begin
        setup_compressor_channel(
            num_sensor,              // sensor channel number (0..3)
            ((num_sensor == 1) || (num_sensor == 3))?  1 : 0, // 0,          // qbank;    // [6:3] quantization table page - 100% quality
    //        1,                       // qbank;    // [6:3] quantization table page - 85%? quality
            1,                       // dc_sub;   // [8:7] subtract DC
            cmode, // CMPRS_CBIT_CMODE_JPEG18, //input [31:0] cmode;   //  [13:9] color mode:
    //        parameter CMPRS_CBIT_CMODE_JPEG18 =   4'h0, // color 4:2:0
    //        parameter CMPRS_CBIT_CMODE_MONO6 =    4'h1, // mono 4:2:0 (6 blocks)
    //        parameter CMPRS_CBIT_CMODE_JP46 =     4'h2, // jp4, 6 blocks, original
    //        parameter CMPRS_CBIT_CMODE_JP46DC =   4'h3, // jp4, 6 blocks, dc -improved
    //        parameter CMPRS_CBIT_CMODE_JPEG20 =   4'h4, // mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
    //        parameter CMPRS_CBIT_CMODE_JP4 =      4'h5, // jp4,  4 blocks, dc-improved
    //        parameter CMPRS_CBIT_CMODE_JP4DC =    4'h6, // jp4,  4 blocks, dc-improved
    //        parameter CMPRS_CBIT_CMODE_JP4DIFF =  4'h7, // jp4,  4 blocks, differential
    //        parameter CMPRS_CBIT_CMODE_JP4DIFFHDR =  4'h8, // jp4,  4 blocks, differential, hdr
    //        parameter CMPRS_CBIT_CMODE_JP4DIFFDIV2 = 4'h9, // jp4,  4 blocks, differential, divide by 2
    //        parameter CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 4'ha, // jp4,  4 blocks, differential, hdr,divide by 2
    //        parameter CMPRS_CBIT_CMODE_MONO1 =    4'hb, // mono JPEG (not yet implemented)
    //        parameter CMPRS_CBIT_CMODE_MONO4 =    4'he, // mono 4 blocks
            1,                      // input [31:0] multi_frame;   // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
            3,  // 0,               // input [31:0] bayer;         // [20:18] // Bayer shift
            0,                      // input [31:0] focus_mode;    // [23:21] Set focus mode
            window_width-1, // 3,    // num_macro_cols_m1; // number of macroblock colums minus 1
            1,                      // num_macro_rows_m1; // number of macroblock rows minus 1
            0, // 1,                // input [31:0] left_margin;       // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
            'bx, // n/a 'h120,      // input [31:0] colorsat_blue; //color saturation for blue (10 bits) //'h90 for 100%
            'bx, // n/a 'h16c,      // colorsat_red; //color saturation for red (10 bits)   // 'b6 for 100%
            0);                     // input [31:0] coring;     // coring value
        // TODO: calculate widths correctly!
        setup_compressor_memory (
                num_sensor,                    // input  [1:0] num_sensor;
                frame_start_address,           // input [31:0] frame_sa;         // 22-bit frame start address ((3 CA LSBs==0. BA==0)
                frame_start_address_inc,       // input [31:0] frame_sa_inc;     // 22-bit frame start address increment  ((3 CA LSBs==0. BA==0)
                last_buf_frame,                // input [31:0] last_frame_num;   // 16-bit number of the last frame in a buffer
                frame_full_width,              // input [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
                window_width, //  & ~3,             // input [31:0] window_width;    // 13 bit - in 8*16=128 bit bursts
                window_height & ~15,           // input [31:0] window_height;   // 16 bit
                window_left,                   // input [31:0] window_left;
                window_top+0,                  // input [31:0] window_top; (to match 20x20 tiles in 353)
                1,   // input        byte32;     // == 1? 
                4,   //input [31:0] tile_width; // == 2
                0,  // input [31:0] extra_pages; // 1
                1,
                16, //    reg   [7:0] tile_height;
                16  //    reg   [7:0] tile_vstep;
                );  // disable "need" (yield to sensor channels)
     end else begin
        $display ("task setup_compressor_channel(): compressor mode %d is not supported",cmode);
        $finish;
     end
    
//    compressor_run (num_sensor, 3); // run repetitive mode
`ifndef COMPRESS_SINGLE
    compressor_run (num_sensor, 3); // run repetitive mode
`endif
    TEST_TITLE = "DELAYS_SETUP";
    $display("===================== TEST_%s =========================",TEST_TITLE);
            
       set_sensor_io_dly (
            num_sensor,                                 // input                            [1:0] num_sensor;
`ifdef HISPI
            128'h33404850_58606870_000000e4_00000007); // input [127:0] dly; // {delays_delays_lane-map_fifo-start_delay]
`else
            128'h33404850_58606870_78808890_98a0a8b0 ); //input [127:0] dly; // {mmsm_phase, bpf, vact, hact, pxd11,...,pxd0]
`endif            
    TEST_TITLE = "IO_SETUP";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_io_width(
            num_sensor, // input    [1:0] num_sensor;
            0); // FULL_WIDTH); // Or use 0 for sensor-generated HACT input   [15:0] width; // 0 - use HACT, >0 - generate HACT from start to specified width
            
        set_sensor_io_ctl (
            num_sensor,  // input                    [1:0] num_sensor;
            3,  // input                            [1:0] mrst;     // <2: keep MRST, 2 - MRST low (active),  3 - high (inactive)
            3,  // input                            [1:0] arst;     // <2: keep ARST, 2 - ARST low (active),  3 - high (inactive)
            TRIGGER_MODE?3:2,   // input            [1:0] aro;      // <2: keep ARO,  2 - set ARO (software controlled) low,  3 - set ARO  (software controlled) high
            0,  // input                            [1:0] mmcm_rst; // <2: keep MMCM reset, 2 - MMCM reset off,  3 - MMCM reset on
            3,  // input                            [1:0] clk_sel;  // <2: keep MMCM clock source, 2 - use internal pixel clock,  3 - use pixel clock from the sensor
            0,  // input                                  set_delays; // (self-clearing) load all pre-programmed delays 
            1'b1,  // input                               set_quadrants;  // 0 - keep quadrants settings, 1 - update quadrants
//            6'h24); // data-0, hact - 1, vact - 2 input  [SENS_CTRL_QUADRANTS_WIDTH-1:0] quadrants;  // 90-degree shifts for data [1:0], hact [3:2] and vact [5:4]
//            6'h01); // data-1, hact - 0, vact - 0 input  [SENS_CTRL_QUADRANTS_WIDTH-1:0] quadrants;  // 90-degree shifts for data [1:0], hact [3:2] and vact [5:4]
            QUADRANTS_PXD_HACT_VACT); // data-0, hact - 1, vact - 2 input  [SENS_CTRL_QUADRANTS_WIDTH-1:0] quadrants;  // 90-degree shifts for data [1:0], hact [3:2] and vact [5:4]
    TEST_TITLE = "I2C_TEST";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        case (num_sensor)
        2'h0: test_i2c_353 (num_sensor,0); // test soft/sequencer i2c
        2'h1: test_i2c_353 (num_sensor,2); // test soft/sequencer i2c
        2'h2: test_i2c_353 (num_sensor,0); // test soft/sequencer i2c
        2'h3: test_i2c_353 (num_sensor,0); // test soft/sequencer i2c
        endcase
        
    TEST_TITLE = "LENS_FLAT_SETUP";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_lens_flat_heights (
            num_sensor, // input   [1:0] num_sensor;
            'hffff,     // input  [15:0] height0_m1; // height of the first sub-frame minus 1
            0,          // input  [15:0] height1_m1; // height of the second sub-frame minus 1
            0);         // input  [15:0] height2_m1; // height of the third sub-frame minus 1 (no need for 4-th)
        set_sensor_lens_flat_parameters(
            num_sensor,
            0, // num_sub_sensor
// add mode "DIRECT", "ASAP", "RELATIVE", "ABSOLUTE" and frame number
            19'h0, // 19'h20000, // 0,      // input  [18:0] AX;
            19'h0, // 19'h20000, // 0,      // input  [18:0] AY;
            21'h0, // 21'h180000, //0,      // input  [20:0] BX;
            21'h0, // 21'h180000, //0,      // input  [20:0] BY;
            'h8000, // input  [18:0] C;
            32768,  // input  [16:0] scales0;
            32768,  // input  [16:0] scales1;
            32768,  // input  [16:0] scales2;
            32768,  // input  [16:0] scales3;
            0,      // input  [15:0] fatzero_in;
            0,      // input  [15:0] fatzero_out;
            1);      // input  [ 3:0] post_scale;
/*
   cpu_wr('h63,'h31020000); // [AX] => 0x20000
   cpu_wr('h63,'h310a0000); // [AY] => 0x20000
*/        
    TEST_TITLE = "GAMMA_SETUP";
    $display("===================== TEST_%s =========================",TEST_TITLE);

        set_sensor_gamma_heights (
            num_sensor, // input   [1:0] num_sensor;
            'hffff,     // input  [15:0] height0_m1; // height of the first sub-frame minus 1
            0,          // input  [15:0] height1_m1; // height of the second sub-frame minus 1
            0);         // input  [15:0] height2_m1; // height of the third sub-frame minus 1 (no need for 4-th)
           
        // Configure histograms
    TEST_TITLE = "HISTOGRAMS_SETUP";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_histogram_window ( // 353 did it using command sequencer)
            num_sensor,          // input   [1:0] num_sensor; // sensor channel number (0..3)
            0,                   // input   [1:0] subchannel; // subchannel number (for multiplexed images)
            HISTOGRAM_LEFT,      // input  [15:0] left;
            HISTOGRAM_TOP,       // input  [15:0] top;
            HISTOGRAM_WIDTH-1,   // input  [15:0] width_m1;  // one less than window width. If 0 - use frame right margin (end of HACT)
            HISTOGRAM_HEIGHT-1); // input  [15:0] height_m1; // one less than window height. If 0 - use frame bottom margin (end of VACT)

        set_sensor_histogram_saxi_addr (
            num_sensor, // input   [1:0] num_sensor; // sensor channel number (0..3)
            0,          // input   [1:0] subchannel; // subchannel number (for multiplexed images)
            HISTOGRAM_START_PAGE); // input  [19:0] page; //start address in 4KB pages (1 page - one subchannel histogram)
            
         set_sensor_histogram_saxi (
            1'b1,                // input         en;
            1'b1,                // input         nrst;
            1'b1,                // input         confirm_write; // wait for the write confirmed before switching channels
            4'h3);               // input   [3:0] cache_mode;    // default should be 4'h3

        // Run after histogram channel is set up?
    TEST_TITLE = "SENSOR_SETUP";
    $display("===================== TEST_%s =========================",TEST_TITLE);
            
        set_sensor_mode (
            num_sensor, // input  [1:0] num_sensor;
            4'h1,       // input  [3:0] hist_en;    // [0..3] 1 - enable histogram modules, disable after processing the started frame
            4'h1,       // input  [3:0] hist_nrst;  // [4..7] 0 - immediately reset histogram module 
            1'b1,       // input        chn_en;     // [8]    1 - enable sensor channel (0 - reset) 
            1'b0);      // input        bits16;     // [9]    0 - 8 bpp mode, 1 - 16 bpp (bypass gamma). Gamma-processed data is still used for histograms
            // test i2c - manual and sequencer (same data as in 353 test fixture

    TEST_TITLE = "CMPRS_EN_ARBIT";
    $display("===================== TEST_%s =========================",TEST_TITLE);
    // just temporarily - enable channel immediately    
    enable_memcntrl_en_dis(4'hc + {2'b0,num_sensor}, 1);
    
    TEST_TITLE = "GAMMA_CTL";
    $display("===================== TEST_%s =========================",TEST_TITLE);
        set_sensor_gamma_ctl (// doing last to enable sensor data when everything else is set up
            num_sensor, // input   [1:0] num_sensor; // sensor channel number (0..3)
            2'h0, // 2'h3,       // input   [1:0] bayer;      // bayer shift (0..3)
            0,          // input         table_page; // table page (only used if SENS_GAMMA_BUFFER)
            1'b1,       // input         en_input;   // enable channel input
            1'b1,       // input         repet_mode; //  Normal mode, single trigger - just for debugging
            1'b0);      // input         trig;       // pass next frame
    // temporarily putting in the very end as it takes about 30 usec to program curves (TODO: see how to make it faster for simulation)
    end
endtask // setup_sensor_channel

task setup_sensor_membridge;
    input  [1:0] num_sensor;
    input        disable_need;
    input        write_video_memory;
    input        rpt;
     
    reg   [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
    reg   [31:0] window_width;    // 13 bit - in 8*16=128 bit bursts
    reg   [31:0] window_height;   // 16 bit
    reg   [31:0] window_left;
    reg   [31:0] window_top;
    reg   [31:0] frame_start_address;
//    reg   [31:0] frame_start_address_inc;
    begin
        window_height = FULL_HEIGHT;
        window_left = 0;
        window_top = 0;
        window_width =       SENSOR_MEMORY_WIDTH_BURSTS;
        frame_full_width =   SENSOR_MEMORY_FULL_WIDTH_BURSTS;
        frame_start_address = FRAME_START_ADDRESS + num_sensor * FRAME_START_ADDRESS_INC * (LAST_BUF_FRAME + 1);
//        frame_start_address_inc = FRAME_START_ADDRESS_INC;
       test_afi_rw (
            write_video_memory,       // write_ddr3;
           SCANLINE_EXTRA_PAGES,      //  extra_pages;
           frame_start_address[21:0], //  input [21:0] frame_start_addr;
           frame_full_width[15:0],    // input [15:0] window_full_width; // 13 bit - in 8*16=128 bit bursts
           window_width[15:0],        // input [15:0] window_width;  // 13 bit - in 8*16=128 bit bursts
           window_height[15:0],       // input [15:0] window_height; // 16 bit (only 14 are used here)
           window_left[15:0],         // input [15:0] window_left;
           window_top[15:0],          // input [15:0] window_top;
           0,                         // input [28:0] start64;  // relative start address of the transfer (set to 0 when writing lo_addr64)
           AFI_LO_ADDR64,             // input [28:0] lo_addr64; // low address of the system memory range, in 64-bit words 
           AFI_SIZE64,                // input [28:0] size64;    // size of the system memory range in 64-bit words
           0,                         // input        continue;    // 0 start from start64, 1 - continue from where it was
           disable_need,
          'h13, //'h3);  // cache_mode;  // 'h3 - normal, 'h13 - debug
           rpt); // repetitive mode
        
    
    end
     
endtask

//x393_camsync.py
task camsync_setup;
    input [3:0]  sensor_mask;
    reg          trigger_mode; // 0 - auto, 1 - triggered
    reg          ext_trigger_mode; // 0 - internal, 1 - external trigger (camsync)
    reg          external_timestamp; // 0 - embed local timestamp, 1 - embed received timestamp
    reg   [31:0] camsync_period;
    reg   [31:0] camsync_delay;
//    reg   [ 3:0] sensor_mask;
    integer i;
    begin
        TEST_TITLE = "CAMSYNC_SETUP";
        $display("===================== TEST_%s =========================",TEST_TITLE);
        camsync_period =     TRIG_PERIOD;
        camsync_delay =      CAMSYNC_DELAY;
        trigger_mode =       TRIGGER_MODE;
        ext_trigger_mode =   EXT_TRIGGER_MODE;
        external_timestamp = EXTERNAL_TIMESTAMP;
//        sensor_mask =        4'hf; // All sensors // 1 << num_sensor;
            
// setup camsync module
        set_camsync_period  (0); // reset circuitry
        set_gpio_ports (
            0,  // input [1:0] port_soft; // <2 - unchanged, 2 - disable, 3 - enable
            3,  // input [1:0] port_a; // camsync
            0,  // input [1:0] port_b; // motors on 353
            0); //input [1:0] port_c; // logger

        set_camsync_mode (
            1'b1,                      // input       en;             // 1 - enable module, 0 - reset
            {1'b1,1'b1},               // input [1:0] en_snd;         // <2 - NOP, 2 - disable, 3 - enable sending timestamp with sync pulse
            {1'b1,external_timestamp}, // input [1:0] en_ts_external; // <2 - NOP, 2 - local timestamp in the frame header, 3 - use external timestamp
            {1'b1,trigger_mode},       // input [1:0] triggered_mode; // <2 - NOP, 2 - async sensor mode, 3 - triggered sensor mode
            {1'b1, 2'h0},              // input [2:0] master_chn;     // <4 - NOP, 4..7 - set master channel
            {1'b1, sensor_mask});      // input [4:0] chn_en;         // <16 - NOP, [3:0] - bit mask of enabled sensor channels
    // setting I/Os after camsync is enabled
        reset_camsync_inout (0);        // reset input selection
        if (ext_trigger_mode)
            set_camsync_inout   (0, 7, 1 ); // set input selection - ext[7], active high
        reset_camsync_inout (1);        // reset output selection
        set_camsync_inout   (1, 6, 1 ); // reset output selection - ext[6], active high
        set_camsync_period  (SYNC_BIT_LENGTH); ///set (bit_length -1) (should be 2..255)
        for (i = 0; i < 4; i = i + 1) begin
            set_camsync_delay (
                i, // 0, // input  [1:0] sub_chn;
                camsync_delay + 10 * i); // input [31:0] dly;          // 0 - input selection, 1 - output selection
        end

        set_camsync_period  (camsync_period); // set period (start generating) - in 353 was after everything else was set
    
    end
endtask

// x393_cmprs_afi.py
task afi_mux_setup;
    input  [3:0] chn_mask;
    input [26:0] afi_cmprs0_sa;   // input [26:0] sa;   // start address in 32-byte chunks
    input [26:0] afi_cmprs0_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
    input [26:0] afi_cmprs1_sa;   // input [26:0] sa;   // start address in 32-byte chunks
    input [26:0] afi_cmprs1_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
    input [26:0] afi_cmprs2_sa;   // input [26:0] sa;   // start address in 32-byte chunks
    input [26:0] afi_cmprs2_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
    input [26:0] afi_cmprs3_sa;   // input [26:0] sa;   // start address in 32-byte chunks
    input [26:0] afi_cmprs3_len; //  input [26:0] length;     // channel buffer length in 32-byte chunks
    integer i;
    begin
        TEST_TITLE = "PROGRAM AFI_MUX";
        $display("===================== TEST_%s =========================",TEST_TITLE);
        for (i = 0; i < 4; i = i+1) if (chn_mask & (1 << i)) begin
            afi_mux_program_status ( 
                0, // input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                                     // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                                     //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                                     // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                                     //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
                i, // num_sensor, // input [1:0] chn_afi;
                3,   // input [1:0] mode;
                0); // input [5:0] seq_num;
        end
        // reset all channels    
        afi_mux_reset(
            0, // input [0:0] port_afi;
            4'hf); // input [3:0] rst_chn;
        // release resets
        afi_mux_reset(
            0, // input [0:0] port_afi;
            0); // input [3:0] rst_chn;
            
        // set report mode (pointer type) - per status    
        for (i = 0; i < 4; i = i+1) if (chn_mask & (1 << i)) begin
            afi_mux_mode_chn (
                0,          //input [0:0] port_afi;    // number of AFI port.3
                i, // num_sensor, // input [1:0] chn;  // channel number to set mode for
    /*
    mode == 0 - show EOF pointer, internal
    mode == 1 - show EOF pointer, confirmed
    mode == 2 - show current pointer, internal
    mode == 3 - show current pointer, confirmed
    each group of 4 bits per channel : bits [1:0] - select, bit[2] - sset (0 - nop), bit[3] - not used
     */    
                0);         // input [1:0] mode; EOF, as sent (not yet confirmed)
//                1);         // input [1:0] mode; EOF confirmed
        end
        afi_mux_chn_start_length (
            0,               // input [0:0] port_afi;    // number of AFI port
            0, // num_sensor,// input [ 1:0] chn;  // channel number to set mode for
            afi_cmprs0_sa,   // input [26:0] sa;   // start address in 32-byte chunks
            afi_cmprs0_len); //  input [26:0] length;     // channel buffer length in 32-byte chunks
        
        afi_mux_chn_start_length (
            0,               // input [0:0] port_afi;    // number of AFI port
            1, // num_sensor,// input [ 1:0] chn;  // channel number to set mode for
            afi_cmprs1_sa,   // input [26:0] sa;   // start address in 32-byte chunks
            afi_cmprs1_len); //  input [26:0] length;     // channel buffer length in 32-byte chunks
// another option - 2 other channels with  port_afi == 1,    chn == [0,1]   
        afi_mux_chn_start_length (
            0,               // input [0:0] port_afi;    // number of AFI port
            2,               // input [ 1:0] chn;  // channel number to set mode for
            afi_cmprs2_sa,   // input [26:0] sa;   // start address in 32-byte chunks
            afi_cmprs2_len); //  input [26:0] length;     // channel buffer length in 32-byte chunks
        
        afi_mux_chn_start_length (
            0,               // input [0:0] port_afi;    // number of AFI port
            3,               // input [ 1:0] chn;  // channel number to set mode for
            afi_cmprs3_sa,   // input [26:0] sa;   // start address in 32-byte chunks
            afi_cmprs3_len); //  input [26:0] length;     // channel buffer length in 32-byte chunks
        
        for (i = 0; i < 4; i = i+1) if (chn_mask & (1 << i)) begin
            // enable channel i
            afi_mux_enable_chn (
                0,          // input [0:0] port_afi;    // number of AFI port
                i, // num_sensor, // input [1:0] en_chn;  // channel number to enable/disable;
                1);         // input       en;
        end
        // enable the whole afi_mux module
    
        afi_mux_enable (
            0,          // input [0:0] port_afi;    // number of AFI port
            1);         // input       en;
    
    end
endtask

//x393_cmprs.py
task setup_compressor_channel;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input [31:0] qbank;    // [6:3] quantization table page
    input [31:0] dc_sub;   // [8:7] subtract DC
    input [31:0] cmode;   //  [13:9] color mode:
//        parameter CMPRS_CBIT_CMODE_JPEG18 =   4'h0, // color 4:2:0
//        parameter CMPRS_CBIT_CMODE_MONO6 =    4'h1, // mono 4:2:0 (6 blocks)
//        parameter CMPRS_CBIT_CMODE_JP46 =     4'h2, // jp4, 6 blocks, original
//        parameter CMPRS_CBIT_CMODE_JP46DC =   4'h3, // jp4, 6 blocks, dc -improved
//        parameter CMPRS_CBIT_CMODE_JPEG20 =   4'h4, // mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
//        parameter CMPRS_CBIT_CMODE_JP4 =      4'h5, // jp4,  4 blocks, dc-improved
//        parameter CMPRS_CBIT_CMODE_JP4DC =    4'h6, // jp4,  4 blocks, dc-improved
//        parameter CMPRS_CBIT_CMODE_JP4DIFF =  4'h7, // jp4,  4 blocks, differential
//        parameter CMPRS_CBIT_CMODE_JP4DIFFHDR =  4'h8, // jp4,  4 blocks, differential, hdr
//        parameter CMPRS_CBIT_CMODE_JP4DIFFDIV2 = 4'h9, // jp4,  4 blocks, differential, divide by 2
//        parameter CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 4'ha, // jp4,  4 blocks, differential, hdr,divide by 2
//        parameter CMPRS_CBIT_CMODE_MONO1 =    4'hb, // mono JPEG (not yet implemented)
//        parameter CMPRS_CBIT_CMODE_MONO4 =    4'he, // mono 4 blocks
    input [31:0] multi_frame;   // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
    input [31:0] bayer;         // [20:18] // Bayer shift
    input [31:0] focus_mode;    // [23:21] Set focus mode
    input [31:0] num_macro_cols_m1; // number of macroblock colums minus 1
    input [31:0] num_macro_rows_m1; // number of macroblock rows minus 1
    input [31:0] left_margin;       // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
    input [31:0] colorsat_blue; //color saturation for blue (10 bits) //'h90 for 100%
    input [31:0] colorsat_red; //color saturation for red (10 bits)   // 'b6 for 100%
    input [31:0] coring;     // coring value

    begin
        TEST_TITLE = "COMPRESSOR_SETUP";
        $display("===================== TEST_%s =========================",TEST_TITLE);
            
        compressor_control(
            num_sensor,    // sensor channel number (0..3)
            'h80000000,    // run_mode; NOP
            qbank,         // [6:3] quantization table page
            dc_sub,        // [8:7] subtract DC
            cmode,         //  [13:9] color mode:
            multi_frame,   // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
            bayer,         // [20:18] // Bayer shift
            focus_mode);   // [23:21] Set focus mode
            
        compressor_format(
            num_sensor,        // sensor channel number (0..3)
            num_macro_cols_m1, // number of macroblock colums minus 1
            num_macro_rows_m1, // number of macroblock rows minus 1
            left_margin);      // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
    
        compressor_color_saturation(
            num_sensor,    // sensor channel number (0..3)
            colorsat_blue, // color saturation for blue (10 bits) //'h90 for 100%
            colorsat_red); // color saturation for red (10 bits)   // 'b6 for 100%

        compressor_coring(
            num_sensor,    // sensor channel number (0..3)
            coring);       // coring value
    end
endtask

// x393_cmprs.py
task compressor_run;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input [31:0] run_mode;  //     input [31:0] run_mode; // [2:0] < 0: nop, 0 - reset, 2 - run single from memory, 3 - run repetitive
    begin
        compressor_control(
            num_sensor,   // sensor channel number (0..3)
            run_mode,     // 0 - reset, 2 - run single from memory, 3 - run repetitive
            'h80000000,   //
            'h80000000,   //
            'h80000000,   //
            'h80000000,   //
            'h80000000,   //
            'h80000000);  //
    end
endtask


// x393_sensor.py
task setup_sensor_memory;
    input  [1:0] num_sensor;
    input [31:0] frame_sa;         // 22-bit frame start address ((3 CA LSBs==0. BA==0)
    input [31:0] frame_sa_inc;     // 22-bit frame start address increment  ((3 CA LSBs==0. BA==0)
    input [31:0] last_frame_num;   // 16-bit number of the last frame in a buffer
    input [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
    input [31:0] window_width;    // 13 bit - in 8*16=128 bit bursts
    input [31:0] window_height;   // 16 bit
    input [31:0] window_left;
    input [31:0] window_top;
    
    reg [29:0] base_addr;
    integer    mode;
    begin
        base_addr = MCONTR_SENS_BASE + MCONTR_SENS_INC * num_sensor;
        mode=   func_encode_mode_scanline(
                    1, // skip_too_late              
                    0, // disable_need
                    1, // repetitive,
                    0, // single,
                    0, // reset_frame,
                    0, // extra_pages,
                    1, // write_mem,
                    1, // enable
                    0);  // chn_reset
        write_contol_register(base_addr + MCNTRL_SCANLINE_STARTADDR,        frame_sa); // RA=80, CA=0, BA=0 22-bit frame start address (3 CA LSBs==0. BA==0)
        write_contol_register(base_addr + MCNTRL_SCANLINE_FRAME_SIZE,       frame_sa_inc);
        write_contol_register(base_addr + MCNTRL_SCANLINE_FRAME_LAST,       last_frame_num);
        write_contol_register(base_addr + MCNTRL_SCANLINE_FRAME_FULL_WIDTH, frame_full_width);
        write_contol_register(base_addr + MCNTRL_SCANLINE_WINDOW_WH,        {window_height[15:0],window_width[15:0]}); //WINDOW_WIDTH + (WINDOW_HEIGHT<<16));
        write_contol_register(base_addr + MCNTRL_SCANLINE_WINDOW_X0Y0,      {window_top[15:0],window_left[15:0]}); //WINDOW_X0+ (WINDOW_Y0<<16));
        write_contol_register(base_addr + MCNTRL_SCANLINE_WINDOW_STARTXY,   32'b0);
        write_contol_register(base_addr + MCNTRL_SCANLINE_MODE,             mode); 
    end
endtask
// x393_cmprs.py
task setup_compressor_memory;
    input  [1:0] num_sensor;
    input [31:0]frame_sa;         // 22-bit frame start address ((3 CA LSBs==0. BA==0)
    input [31:0] frame_sa_inc;     // 22-bit frame start address increment  ((3 CA LSBs==0. BA==0)
    input [31:0] last_frame_num;   // 16-bit number of the last frame in a buffer
    input [31:0] frame_full_width; // 13-bit Padded line length (8-row increment), in 8-bursts (16 bytes)
    input [31:0] window_width;    // 13 bit - in 8*16=128 bit bursts
    input [31:0] window_height;   // 16 bit
    input [31:0] window_left;
    input [31:0] window_top;
    input        byte32;     // == 1? 
    input [31:0] tile_width; // == 2
    input [31:0] extra_pages; // 1
    input        disable_need; // set to 1
    input  [7:0] tile_height;
    input  [7:0] tile_vstep;
    
    reg [29:0] base_addr;
    integer    mode;
//    reg   [7:0] tile_height;
//    reg   [7:0] tile_vstep;
    begin
//        tile_vstep = 16;
//        tile_height= 18;
        
        
        base_addr = MCONTR_CMPRS_BASE + MCONTR_CMPRS_INC * num_sensor;
        mode=   func_encode_mode_tiled(
                    1'b0,             // skip too late
                    disable_need,
                    1,                // repetitive,
                    0,                // single,
                    0,                // reset_frame,
                    byte32,           // byte32,
                    0,                // keep_open,
                    extra_pages[1:0], // extra_pages
                    0,                // write_mem,
                    1,                // enable
                    0);               // chn_reset
                    
        write_contol_register(base_addr + MCNTRL_TILED_STARTADDR,        frame_sa); // RA=80, CA=0, BA=0 22-bit frame start address (3 CA LSBs==0. BA==0)
        write_contol_register(base_addr + MCNTRL_TILED_FRAME_SIZE,       frame_sa_inc);
        write_contol_register(base_addr + MCNTRL_TILED_FRAME_LAST,       last_frame_num);
        write_contol_register(base_addr + MCNTRL_TILED_FRAME_FULL_WIDTH, frame_full_width);
        write_contol_register(base_addr + MCNTRL_TILED_WINDOW_WH,        {window_height[15:0],window_width[15:0]}); //WINDOW_WIDTH + (WINDOW_HEIGHT<<16));
        write_contol_register(base_addr + MCNTRL_TILED_WINDOW_X0Y0,      {window_top[15:0],window_left[15:0]}); //WINDOW_X0+ (WINDOW_Y0<<16));
        write_contol_register(base_addr + MCNTRL_TILED_WINDOW_STARTXY,   32'b0);
        write_contol_register(base_addr + MCNTRL_TILED_TILE_WHS,         {8'b0,tile_vstep,tile_height,tile_width[7:0]});//(tile_height<<8)+(tile_vstep<<16));
        write_contol_register(base_addr + MCNTRL_TILED_MODE,             mode); 
    end
endtask



task test_i2c_353;
    input [1:0] chn;
    input integer num_extra;
    integer i;
    begin
    // Reset moved out, done for all channels, then 1 usec delay
        set_sensor_i2c_command (chn, 0, 3, 0, 0, 0); // run i2c
        write_sensor_i2c (chn, 1, 0,'h90050922);
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 1, 0, i+ 'h12);
        write_sensor_i2c (chn, 1, 0,'h91900004);
//write_sensor_i2c  0 1 0 0x91900004
//read_sensor_i2c 0

        write_sensor_i2c (
            chn,           // input   [1:0] num_sensor;
            0,           // input         rel_addr; // 0 - absolute, 1 - relative
            1,           // input integer addr;
            'h90040793); // input  [31:0] data;
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 0, 1, i+ 'h1);
        write_sensor_i2c (chn, 0, 1,'h90050a23);
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 0, 1, i+ 'h123);
        write_sensor_i2c (chn, 0, 2,'h90080001);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 0, 2, i+ 'h1234);
        write_sensor_i2c (chn, 0, 3,'h90090123);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 0, 3, i+ 'h12345);
        write_sensor_i2c (chn, 1, 2,'h90091234);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 1, 2, i+ 'h123456);
        write_sensor_i2c (chn, 0, 4,'h9004001f);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 0, 4, i+ 'h1234567);
        write_sensor_i2c (chn, 0, 4,'h9005002f);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 0, 4, i+ 'h12345678);
        write_sensor_i2c (chn, 1, 3,'h90020013);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 1, 3, i+ 'h4567);
        write_sensor_i2c (chn, 1, 3,'h90030017);        
        for (i=0; i<num_extra; i=i+1) write_sensor_i2c (chn, 1, 3, i+ 'h456789);
    
    end
endtask


//x393_sensor.py
task program_status_sensor_i2c;
    input [1:0] num_sensor;
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC + SENSI2C_CTRL_RADDR,
                        SENSI2C_STATUS,
                        mode,
                        seq_num);
    end
endtask

//x393_sensor.py
task program_status_sensor_io;
    input [1:0] num_sensor;
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC + SENSIO_RADDR,
                        SENSIO_STATUS,
                        mode,
                        seq_num);
    end
endtask

//x393_cmprs.py
task program_status_compressor;
    input [1:0] num_sensor;
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC,
                        CMPRS_STATUS_CNTRL,
                        mode,
                        seq_num);
    end
endtask

task program_status_frame_sequencer;
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (CMDSEQMUX_ADDR,
                        0, // only register
                        mode,
                        seq_num);
    end
endtask

//x393_gpio.py
task program_status_gpio;
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (GPIO_ADDR,
                        GPIO_SET_STATUS,
                        mode,
                        seq_num);
    end
endtask

//x393_gpio.py
task set_gpio_ports;
    input [1:0] port_soft; // <2 - unchanged, 2 - disable, 3 - enable
    input [1:0] port_a; // camsync
    input [1:0] port_b; // motors on 353
    input [1:0] port_c; // logger
    
    reg  [31:0] data;
    begin
        data = 0;
        data [GPIO_PORTEN + 0 +:2] = port_soft;
        data [GPIO_PORTEN + 2 +:2] = port_a;
        data [GPIO_PORTEN + 4 +:2] = port_b;
        data [GPIO_PORTEN + 6 +:2] = port_c;
        write_contol_register( GPIO_ADDR + GPIO_SET_PINS, data << GPIO_PORTEN);
    end
endtask
    
//x393_gpio.py
task set_gpio_pins;
    input [1:0] ext0; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext1; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext2; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext3; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext4; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext5; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext6; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext7; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext8; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    input [1:0] ext9; // 0 - nop, 1 - set "0", 2 - set "1", 3 - set as input
    
    reg  [31:0] data;
    begin
        data = 0;
        data [ 0 +:2] = ext0;
        data [ 2 +:2] = ext1;
        data [ 4 +:2] = ext2;
        data [ 6 +:2] = ext3;
        data [ 8 +:2] = ext4;
        data [10 +:2] = ext5;
        data [12 +:2] = ext6;
        data [14 +:2] = ext7;
        data [16 +:2] = ext8;
        data [18 +:2] = ext9;
        write_contol_register( GPIO_ADDR + GPIO_SET_PINS, data);
    end
endtask

// x393_sensor.py
task set_sensor_mode;
    input  [1:0] num_sensor;
    input  [3:0] hist_en;    // [0..3] 1 - enable histogram modules, disable after processing the started frame
    input  [3:0] hist_nrst;  // [4..7] 0 - immediately reset histogram module 
    input        chn_en;     // [8]    1 - enable sensor channel (0 - reset) 
    input        bits16;     // [9]    0 - 8 bpp mode, 1 - 16 bpp (bypass gamma). Gamma-processed data is still used for histograms
    reg    [31:0]      tmp;
    begin
        tmp= {{(32-SENSOR_MODE_WIDTH){1'b0}},func_sensor_mode(hist_en, hist_nrst, chn_en,bits16)};
        write_contol_register( SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC +SENSOR_CTRL_RADDR, tmp);
    end
     
endtask
    
// x393_sensor.py
task set_sensor_i2c_command;
    input                             [1:0] num_sensor;
    input                                   rst_cmd;    // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
    input       [SENSI2C_CMD_RUN_PBITS : 0] run_cmd;    // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
    input                                   set_active; 
    input                                   active_sda; 
    input                                   early_release_0; 

    reg                              [31:0] tmp;

    begin
    // only needs wait busy for software i2c
//        #80; // instead of wait busy - check if it is needed
        tmp= {func_sensor_i2c_command(rst_cmd, run_cmd, set_active, active_sda, early_release_0)};
        write_contol_register( SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC +SENSI2C_CTRL_RADDR, tmp);
    end
endtask

task set_sensor_i2c_table_reg_wr;
    input                             [1:0] num_sensor;
    input                             [7:0] page;       // set parameters for 32-bit command with this MSB
    input                             [6:0] slave_addr; // 7-bit slave address
    input                             [7:0] rah;        // register address high byte
    input                             [3:0] num_bytes;  // number of bytes to send
    input                             [7:0] bit_delay;

    reg                              [31:0] tmp;

    begin
    // set table address
        tmp = 0;
        tmp [SENSI2C_CMD_TABLE] = 1;
        tmp [SENSI2C_CMD_TAND] =  1;
        tmp [7:0]              =  page;
        write_contol_register( SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC +SENSI2C_CTRL_RADDR, tmp);
        // write table entry
        tmp = {4'b0, func_sensor_i2c_table_reg_wr(slave_addr, rah, num_bytes, bit_delay)};
        tmp [SENSI2C_CMD_TABLE] = 1;
        write_contol_register( SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC +SENSI2C_CTRL_RADDR, tmp);
    end
endtask

task set_sensor_i2c_table_reg_rd;
    input                             [1:0] num_sensor;
    input                             [7:0] page;       // set parameters for 32-bit command with this MSB
    input                                   num_bytes_addr; // number of address bytes (0 - 1, 1 - 2)
    input                             [2:0] num_bytes_rd;  // number of bytes to read, with "0" meaning all 8
    input                             [7:0] bit_delay;

    reg                              [31:0] tmp;

    begin
    // set table address
        tmp = 0;
        tmp [SENSI2C_CMD_TABLE] = 1;
        tmp [SENSI2C_CMD_TAND] =  1;
        tmp [7:0]              =  page;
        write_contol_register( SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC +SENSI2C_CTRL_RADDR, tmp);
        // write table entry
        tmp = {4'b0, func_sensor_i2c_table_reg_rd(num_bytes_addr, num_bytes_rd, bit_delay)};
        tmp [SENSI2C_CMD_TABLE] = 1;
        write_contol_register( SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC +SENSI2C_CTRL_RADDR, tmp);
    end
endtask


// x393_sensor.py
task write_sensor_i2c;
    input   [1:0] num_sensor;
    input         rel_addr; // 0 - absolute, 1 - relative
    input integer addr;
    input  [31:0] data;
    reg    [29:0] reg_addr;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) +
                   (rel_addr ? SENSI2C_REL_RADDR : SENSI2C_ABS_RADDR) +
                   (addr & ~SENSI2C_ADDR_MASK);
        write_contol_register(reg_addr, data);                   
    end
endtask



// x393_sensor.py
task    set_sensor_io_ctl;
    input                            [1:0] num_sensor;
    input                            [1:0] mrst;     // <2: keep MRST, 2 - MRST low (active),  3 - high (inactive)
    input                            [1:0] arst;     // <2: keep ARST, 2 - ARST low (active),  3 - high (inactive)
    input                            [1:0] aro;      // <2: keep ARO,  2 - set ARO (software controlled) low,  3 - set ARO  (software controlled) high
    input                            [1:0] mmcm_rst; // <2: keep MMCM reset, 2 - MMCM reset off,  3 - MMCM reset on
    input                            [1:0] clk_sel;  // <2: keep MMCM clock source, 2 - use internal pixel clock,  3 - use pixel clock from the sensor
    input                                  set_delays; // (self-clearing) load all pre-programmed delays 
    input                                  set_quadrants;  // 0 - keep quadrants settings, 1 - update quadrants
    input  [SENS_CTRL_QUADRANTS_WIDTH-1:0] quadrants;  // 90-degree shifts for data [1:0], hact [3:2] and vact [5:4]
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENSIO_RADDR + SENSIO_CTRL;
        if (clk_sel & 2) begin // reset MMCM before changing clock source
            data = func_sensor_io_ctl (
                        0, // mrst,
                        0, // arst,
                        0, // aro,
                        3, // mmcm_rst,
                        0, // clk_sel,
                        0, // set_delays,
                        0, // set_quadrants,
                        0); // quadrants);
            write_contol_register(reg_addr, data);                   
        end
        data = func_sensor_io_ctl (
                    mrst,
                    arst,
                    aro,
                    0, // mmcm_rst,
                    clk_sel,
                    set_delays,
                    set_quadrants,
                    quadrants);
        write_contol_register(reg_addr, data);                   

        if ((clk_sel & 2) && !(mmcm_rst == 3)) begin // release reset MMCM after changing clock source (only if it was not requested on)
            data = func_sensor_io_ctl (
                        0, // mrst,
                        0, // arst,
                        0, // aro,
                        2, // mmcm_rst,
                        0, // clk_sel,
                        0, // set_delays,
                        0, // set_quadrants,
                        0); // quadrants);
            write_contol_register(reg_addr, data);                   
        end

    end
endtask

// x393_sensor.py
task    set_sensor_io_dly;
    input                            [1:0] num_sensor;
    input [127:0] dly; // {mmsm_phase, bpf, vact, hact, pxd11,...,pxd0]
    reg    [29:0] reg_addr;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENSIO_RADDR + SENSIO_DELAYS;
        write_contol_register(reg_addr + 0, dly[ 31: 0]); // {pxd3,       pxd2,  pxd1, pxd0}
        write_contol_register(reg_addr + 1, dly[ 63:32]); // {pxd7,       pxd6,  pxd5, pxd4}
        write_contol_register(reg_addr + 2, dly[ 95:64]); // {pxd11,      pxd10, pxd9, pxd8}
        write_contol_register(reg_addr + 3, dly[127:96]); // {mmcm_phase, bpf,   vact, hact}
        set_sensor_io_ctl(
            num_sensor,
            0, // input                            [1:0] mrst;     // <2: keep MRST, 2 - MRST low (active),  3 - high (inactive)
            0, // input                            [1:0] arst;     // <2: keep ARST, 2 - ARST low (active),  3 - high (inactive)
            0, // input                            [1:0] aro;      // <2: keep ARO,  2 - set ARO (software controlled) low,  3 - set ARO  (software controlled) high
            0, // input                            [1:0] mmcm_rst; // <2: keep MMCM reset, 2 - MMCM reset off,  3 - MMCM reset on
            0, // input                            [1:0] clk_sel;  // <2: keep MMCM clock source, 2 - use internal pixel clock,  3 - use pixel clock from the sensor
            1'b1, //input                                  set_delays; // (self-clearing) load all pre-programmed delays 
            0,   // input                                  set_quadrants;  // 0 - keep quadrants settings, 1 - update quadrants
            0); // input  [SENS_CTRL_QUADRANTS_WIDTH-1:0] quadrants;  // 90-degree shifts for data [1:0], hact [3:2] and vact [5:4]
    
    end
endtask

// x393_sensor.py
task    set_sensor_io_jtag; // SuppressThisWarning VEditor - may be unused
    input                            [1:0] num_sensor;
    input                            [1:0] pgmen;    // <2: keep PGMEN, 2 - PGMEN low (inactive),  3 - high (active) enable JTAG control
    input                            [1:0] prog;     // <2: keep prog, 2 - prog low (active),  3 - high (inactive) ("program" pin control)
    input                            [1:0] tck;      // <2: keep TCK,  2 - set TCK low,  3 - set TCK high
    input                            [1:0] tms;      // <2: keep TMS,  2 - set TMS low,  3 - set TMS high
    input                            [1:0] tdi;      // <2: keep TDI,  2 - set TDI low,  3 - set TDI high
    reg    [29:0] reg_addr;
    reg    [31:0] data;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENSIO_RADDR + SENSIO_JTAG;
        data = func_sensor_jtag_ctl (
            pgmen,    // <2: keep PGMEN, 2 - PGMEN low (inactive),  3 - high (active) enable JTAG control
            prog,     // <2: keep prog, 2 - prog low (active),  3 - high (inactive) ("program" pin control)
            tck,      // <2: keep TCK,  2 - set TCK low,  3 - set TCK high
            tms,      // <2: keep TMS,  2 - set TMS low,  3 - set TMS high
            tdi);     // <2: keep TDI,  2 - set TDI low,  3 - set TDI high
        write_contol_register(reg_addr, data);
    end
endtask

// x393_sensor.py
task    set_sensor_io_width;
    input    [1:0] num_sensor;
    input   [15:0] width; // 0 - use HACT, >0 - generate HACT from start to specified width
    reg     [29:0] reg_addr;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENSIO_RADDR + SENSIO_WIDTH;
        write_contol_register(reg_addr, {16'b0, width});
    end
    

endtask

// x393_sensor.py
task set_sensor_lens_flat_heights;
    input   [1:0] num_sensor;
    input  [15:0] height0_m1; // height of the first sub-frame minus 1
    input  [15:0] height1_m1; // height of the second sub-frame minus 1
    input  [15:0] height2_m1; // height of the third sub-frame minus 1 (no need for 4-th)
    reg    [29:0] reg_addr;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_LENS_RADDR;
        write_contol_register(reg_addr, {16'b0, height0_m1});                   
        write_contol_register(reg_addr+1, {16'b0, height1_m1});                   
        write_contol_register(reg_addr+2, {16'b0, height2_m1});                   
    end
endtask

// x393_sensor.py
task set_sensor_lens_flat_parameters;
    input   [1:0] num_sensor;
    input   [1:0] num_sub_sensor;
// add mode "DIRECT", "ASAP", "RELATIVE", "ABSOLUTE" and frame number
    input  [18:0] AX;
    input  [18:0] AY;
    input  [20:0] BX;
    input  [20:0] BY;
    input  [18:0] C;
    input  [16:0] scales0;
    input  [16:0] scales1;
    input  [16:0] scales2;
    input  [16:0] scales3;
    input  [15:0] fatzero_in;
    input  [15:0] fatzero_out;
    input  [ 3:0] post_scale;
    reg    [29:0] reg_addr;
    reg    [31:0] data;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_LENS_RADDR + SENS_LENS_COEFF;
        data = func_lens_data(num_sub_sensor, SENS_LENS_AX);
        data[18:0] = AX;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_AY);
        data[18:0]  = AY;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_C);
        data[18:0]  = C;
        write_contol_register(reg_addr, data);
        data = func_lens_data(num_sub_sensor, SENS_LENS_BX);
        data[20:0]  = BX;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_BY);
        data[20:0]  = BY;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_SCALES + 0);
        data[16:0]  = scales0;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_SCALES + 2);
        data[16:0]  = scales1;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_SCALES + 4);
        data[16:0]  = scales2;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_SCALES + 6);
        data[16:0]  = scales3;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_FAT0_IN);
        data[15:0]  = fatzero_in;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_FAT0_OUT);
        data[15:0]  = fatzero_out;
        write_contol_register(reg_addr, data);                   
        data = func_lens_data(num_sub_sensor, SENS_LENS_POST_SCALE);
        data[3:0]  = post_scale;
        write_contol_register(reg_addr, data);                   
    end
endtask

// x393_sensor.py
function [31:0] func_lens_data;
    input   [1:0] num_sensor;
    input   [7:0] addr;
    begin
        func_lens_data = {6'b0, num_sensor, addr,16'b0};
    end
endfunction


// x393_sensor.py
task program_curves;
    input   [1:0] num_sensor;
    input   [1:0] sub_channel;
    reg   [9:0]   curves_data[0:1027];  // SuppressThisWarning VEditor : assigned in $readmem() system task
    integer n,i,base,diff,diff1;
//    reg [10:0] curv_diff;
    reg    [17:0] data18;
    begin
        $readmemh("input_data/linear1028rgb.dat",curves_data);
         set_sensor_gamma_table_addr (
            num_sensor,
            sub_channel,
            2'b0,         //input   [1:0] color;
            1'b0);        //input         page; // only used if SENS_GAMMA_BUFFER != 0
        
        for (n=0;n<4;n=n+1) begin
          for (i=0;i<256;i=i+1) begin
            base =curves_data[257*n+i];
            diff =curves_data[257*n+i+1]-curves_data[257*n+i];
            diff1=curves_data[257*n+i+1]-curves_data[257*n+i]+8;
    //        $display ("%x %x %x %x %x %x",n,i,curves_data[257*n+i], base, diff, diff1);
            #1;
            if ((diff>63) || (diff < -64)) data18 = {1'b1,diff1[10:4],base[9:0]};
            else                           data18 = {1'b0,diff [ 6:0],base[9:0]};
            set_sensor_gamma_table_data ( // need 256 for a single color data
                num_sensor,
                data18); // 18-bit table data
            
          end
        end  
    end
endtask

task program_huffman;
    input   [1:0] chn;
    reg    [29:0] reg_addr;
    reg    [23:0]   huff_data[0:511]; // SuppressThisWarning VEditor : assigned in $readmem() system task
    integer i;
    begin
        $readmemh("input_data/huffman.dat",huff_data);
        reg_addr = (CMPRS_GROUP_ADDR + chn * CMPRS_BASE_INC) + CMPRS_TABLES; // for data, adderss is "reg_addr + 1"
        write_contol_register(reg_addr + 1, (TABLE_HUFFMAN_INDEX << 24) + 0);                   
        for (i=0;i<512;i=i+1) begin
            write_contol_register(reg_addr, {8'b0, huff_data[i]});
        end
    end
endtask
    
task program_quantization;
    input   [1:0] chn;
    reg    [29:0] reg_addr;
    reg    [15:0]   quant_data[0:255]; //  Actually 4 pairs of tables, 1 table is just 64 words SuppressThisWarning VEditor : assigned in $readmem() system task
    integer i;
    begin
        $readmemh("input_data/quantization_100.dat",quant_data);
        reg_addr = (CMPRS_GROUP_ADDR + chn * CMPRS_BASE_INC) + CMPRS_TABLES;       // for data, adderss is "reg_addr + 1"
        write_contol_register(reg_addr + 1, (TABLE_QUANTIZATION_INDEX << 24) + 0); // 64*table_number                 
        for (i=0;i<256;i=i+2) begin
            write_contol_register(reg_addr, {quant_data[i+1],quant_data[i]});
        end
    end
endtask

task program_coring;
    input  [1:0] chn;
    reg   [29:0] reg_addr;
    reg   [15:0] coring_data[0:1023]; // SuppressThisWarning VEditor : assigned in $readmem() system task
    integer i;
    begin
        $readmemh("input_data/coring.dat",coring_data);
        reg_addr = (CMPRS_GROUP_ADDR + chn * CMPRS_BASE_INC) + CMPRS_TABLES; // for data, adderss is "reg_addr + 1"
        write_contol_register(reg_addr + 1, (TABLE_CORING_INDEX << 24) + 0); // start address of coring tables
        for (i=0;i<1024;i=i+2) begin
          write_contol_register(reg_addr, {coring_data[i+1], coring_data[i]});
        end
    end
endtask



task program_focus_filt;
    input  [1:0] chn;
    reg   [29:0] reg_addr;
    reg   [15:0] filt_data[0:127]; // SuppressThisWarning VEditor : assigned in $readmem() system task
    integer i;
    begin
        $readmemh("input_data/focus_filt.dat",filt_data);
        reg_addr = (CMPRS_GROUP_ADDR + chn * CMPRS_BASE_INC) + CMPRS_TABLES; // for data, adderss is "reg_addr + 1"
        write_contol_register(reg_addr + 1, (TABLE_FOCUS_INDEX << 24) + 0);  // start address of focus filter tables
        for (i=0;i<128;i=i+2) begin
            write_contol_register(reg_addr, {filt_data[i+1], filt_data[i]});
        end
    end
endtask





// x393_sensor.py
task set_sensor_gamma_table_addr;
    input   [1:0] num_sensor;
    input   [1:0] sub_channel;
    input   [1:0] color;
    input         page; // only used if SENS_GAMMA_BUFFER != 0

    reg    [31:0] data;
    reg    [29:0] reg_addr;
    
    begin
        data =      0;
        data [20] = 1'b1;
        data [7:0] = 8'b0;
        data [9:8] = color;
        if (SENS_GAMMA_BUFFER) data[12:10] = {sub_channel[1:0], page};
        else                   data[11:10] = sub_channel[1:0];

        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_GAMMA_RADDR + SENS_GAMMA_ADDR_DATA;
        write_contol_register(reg_addr, data);                   

    end

endtask

// x393_sensor.py
task set_sensor_gamma_table_data; // need 256 for a single color data
    input   [1:0] num_sensor;
    input  [17:0] data18; // 18-bit table data

    reg    [29:0] reg_addr;
    
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_GAMMA_RADDR + SENS_GAMMA_ADDR_DATA;
        write_contol_register(reg_addr, {14'b0, data18});                   
    end

endtask

// x393_sensor.py
task set_sensor_gamma_heights;
    input   [1:0] num_sensor;
    input  [15:0] height0_m1; // height of the first sub-frame minus 1
    input  [15:0] height1_m1; // height of the second sub-frame minus 1
    input  [15:0] height2_m1; // height of the third sub-frame minus 1 (no need for 4-th)
    reg    [29:0] reg_addr;
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_GAMMA_RADDR + SENS_GAMMA_HEIGHT01;
        write_contol_register(reg_addr, {height1_m1, height0_m1});                   

        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_GAMMA_RADDR + SENS_GAMMA_HEIGHT2;
        write_contol_register(reg_addr, {16'b0,  height2_m1});                   
    end
endtask

// x393_sensor.py
task set_sensor_gamma_ctl;
    input   [1:0] num_sensor; // sensor channel number (0..3)
    input   [1:0] bayer;      // bayer shift (0..3)
    input         table_page; // table page (only used if SENS_GAMMA_BUFFER)
    input         en_input;   // enable channel input
    input         repet_mode; //  Normal mode, single trigger - just for debugging
    input         trig;       // pass next frame
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;

    begin
        data = func_sensor_gamma_ctl (
                    bayer,
                    table_page,
                    en_input,
                    repet_mode,
                    trig);
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC) + SENS_GAMMA_RADDR + SENS_GAMMA_CTRL;
        write_contol_register(reg_addr, data);                   
    end
    
endtask

// x393_sensor.py
task set_sensor_histogram_window;
    input   [1:0] num_sensor; // sensor channel number (0..3)
    input   [1:0] subchannel; // subchannel number (for multiplexed images)
    input  [15:0] left;
    input  [15:0] top;
    input  [15:0] width_m1;  // one less than window width. If 0 - use frame right margin (end of HACT)
    input  [15:0] height_m1; // one less than window height. If 0 - use frame bottom margin (end of VACT)
//    reg    [31:0] data;
    reg    [29:0] reg_addr;
    
    begin
        reg_addr = (SENSOR_GROUP_ADDR + num_sensor * SENSOR_BASE_INC); // + HISTOGRAM_LEFT_TOP;
        case (subchannel[1:0]) 
            2'h0: reg_addr = reg_addr + HISTOGRAM_RADDR0;
            2'h1: reg_addr = reg_addr + HISTOGRAM_RADDR1;
            2'h2: reg_addr = reg_addr + HISTOGRAM_RADDR2;
            2'h3: reg_addr = reg_addr + HISTOGRAM_RADDR3;
        endcase
        write_contol_register(reg_addr + HISTOGRAM_LEFT_TOP,     {top,    left});
        write_contol_register(reg_addr + HISTOGRAM_WIDTH_HEIGHT, {height_m1, width_m1});
    end
endtask

// x393_sensor.py
task set_sensor_histogram_saxi;
    input         en;
    input         nrst;
    input         confirm_write; // wait for the write confirmed before switching channels
    input   [3:0] cache_mode;    // default should be 4'h3
    reg    [31:0] data;
    begin
        data = 0;
        data [HIST_SAXI_EN] =     en;
        data [HIST_SAXI_NRESET] = nrst;
        data [HIST_CONFIRM_WRITE] = confirm_write;
        data [HIST_SAXI_AWCACHE +: 4] = cache_mode;
        write_contol_register(SENSOR_GROUP_ADDR + HIST_SAXI_MODE_ADDR_REL, data);
    end
endtask
    
// x393_sensor.py
task set_sensor_histogram_saxi_addr;
    input   [1:0] num_sensor; // sensor channel number (0..3)
    input   [1:0] subchannel; // subchannel number (for multiplexed images)
    input  [19:0] page; //start address in 4KB pages (1 page - one subchannel histogram)
    begin
        write_contol_register(SENSOR_GROUP_ADDR + HIST_SAXI_ADDR_REL + (num_sensor << 2) + subchannel,{12'b0,page});
    end
endtask
    
// x393_sensor.py
function [STATUS_DEPTH-1:0] func_status_addr_sensor_i2c;
    input [1:0] num_sensor;
    begin
        func_status_addr_sensor_i2c = (SENSI2C_STATUS_REG_BASE + num_sensor * SENSI2C_STATUS_REG_INC + SENSI2C_STATUS_REG_REL);
    end
endfunction

// x393_sensor.py
function [STATUS_DEPTH-1:0] func_status_addr_sensor_io;
    input [1:0] num_sensor;
    begin
        func_status_addr_sensor_io = (SENSI2C_STATUS_REG_BASE + num_sensor * SENSI2C_STATUS_REG_INC + SENSIO_STATUS_REG_REL);
    end
endfunction

// RTC tasks
// x393_rtc.py
task program_status_rtc; // set status mode, and take a time snapshot (wait response and read time)
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (RTC_ADDR,
                        RTC_SET_STATUS,
                        mode,
                        seq_num);
    end
endtask


// x393_rtc.py
task set_rtc;
    input [31:0] sec;
    input [19:0] usec;
    input [15:0] corr;
    begin
        write_contol_register(RTC_ADDR + RTC_SET_CORR,{16'b0,corr});
        write_contol_register(RTC_ADDR + RTC_SET_USEC,{12'b0,usec});
        write_contol_register(RTC_ADDR + RTC_SET_SEC, sec);
    end
endtask

/*
function [STATUS_DEPTH-1:0] func_status_addr_rtc_status;
    begin
        func_status_addr_rtc_status = RTC_STATUS_REG_ADDR;
    end
endfunction

function [STATUS_DEPTH-1:0] func_status_addr_rtc_usec; // sec is in the next address
    begin
        func_status_addr_rtc_usec = RTC_SEC_USEC_ADDR;
    end
endfunction
*/
// camsync tasks 
// x393_camsync.py
task set_camsync_mode;
    input       en;             // 1 - enable, 0 - reset module
    input [1:0] en_snd;         // <2 - NOP, 2 - disable, 3 - enable sending timestamp with sync pulse
    input [1:0] en_ts_external; // <2 - NOP, 2 - local timestamp in the frame header, 3 - use external timestamp
    input [1:0] triggered_mode; // <2 - NOP, 2 - async sensor mode, 3 - triggered sensor mode
    input [2:0] master_chn;     // <4 - NOP, 4..7 - set master channel
    input [4:0] chn_en;         // <16 - NOP, [3:0] - bit mask of enabled sensor channels
    reg    [31:0] data;
    begin
        data = 0;
        data [CAMSYNC_EN_BIT]             = en;
        data [CAMSYNC_SNDEN_BIT     -: 2] = en_snd;
        data [CAMSYNC_EXTERNAL_BIT  -: 2] = en_ts_external;
        data [CAMSYNC_TRIGGERED_BIT -: 2] = triggered_mode;
        data [CAMSYNC_MASTER_BIT    -: 3] = master_chn;
        data [CAMSYNC_CHN_EN_BIT    -: 5] = chn_en;
        write_contol_register(CAMSYNC_ADDR + CAMSYNC_MODE, data);
    end
endtask

// x393_camsync.py
task set_camsync_inout; // set specified input bit, keep other ones
    input         is_out;          // 0 - input selection, 1 - output selection
    input integer bit_number;      // 0..9 - bit to use
    input         active_positive; // 0 - active negative pulse, 1 - active positive pulse,
    reg    [31:0] data;
    begin
        data = {32'h00055555};
        data[2 * bit_number +: 2 ] = {1'b1, active_positive};
        if (is_out) write_contol_register(CAMSYNC_ADDR + CAMSYNC_TRIG_DST, data);
        else        write_contol_register(CAMSYNC_ADDR + CAMSYNC_TRIG_SRC, data);
    end
endtask

// x393_camsync.py
task reset_camsync_inout; // disable all inputs
    input         is_out;          // 0 - input selection, 1 - output selection
    begin
        if (is_out) write_contol_register(CAMSYNC_ADDR + CAMSYNC_TRIG_DST, 0);
        else        write_contol_register(CAMSYNC_ADDR + CAMSYNC_TRIG_SRC, 0);
    end
endtask

// x393_camsync.py
task set_camsync_period;
    input [31:0] period;          // 0 - input selection, 1 - output selection
    begin
        write_contol_register(CAMSYNC_ADDR + CAMSYNC_TRIG_PERIOD, period);
    end
endtask

// x393_camsync.py
task set_camsync_delay;
    input  [1:0] sub_chn;
    input [31:0] dly;          // 0 - input selection, 1 - output selection
    begin
        write_contol_register(CAMSYNC_ADDR + CAMSYNC_TRIG_DELAY0 + sub_chn, dly);
    end
endtask
// command sequencer control

// Functions used by sensor-related tasks
// x393_frame_sequencer.py

task frame_sequencer_irq_en;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input        en;         // 1 - enable, 0 - disable interrupts
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        data = (en? 3 : 2)  << CMDFRAMESEQ_IRQ_BIT;
        reg_addr= CMDFRAMESEQ_ADDR_BASE + num_sensor * CMDFRAMESEQ_ADDR_INC + CMDFRAMESEQ_CTRL;
        write_contol_register(reg_addr, data);                   
    end
endtask

task frame_sequencer_irq_clear;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    
    reg    [29:0] reg_addr;
    begin
        reg_addr= CMDFRAMESEQ_ADDR_BASE + num_sensor * CMDFRAMESEQ_ADDR_INC + CMDFRAMESEQ_CTRL;
        write_contol_register_irq(reg_addr, 1 << CMDFRAMESEQ_IRQ_BIT);                   
    end
endtask


task ctrl_cmd_frame_sequencer;
    input [1:0] num_sensor; // sensor channel number
    input       reset;      // reset sequencer (also stops)
    input       start;      // start sequencer
    input       stop;       // stop sequencer

    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        reg_addr= CMDFRAMESEQ_ADDR_BASE + num_sensor * CMDFRAMESEQ_ADDR_INC + CMDFRAMESEQ_CTRL;
        data = 0;
        data [CMDFRAMESEQ_RST_BIT] = reset;
        data [CMDFRAMESEQ_RUN_BIT -:2] = {start | stop, start};
        write_contol_register(reg_addr, data);
    end
endtask

// x393_frame_sequencer.py
task write_cmd_frame_sequencer;
    input                  [1:0] num_sensor; // sensor channel number
    input                        relative;   // 0 - absolute (address = 0..f), 1 - relative (address= 0..e)
    input                  [3:0] frame_addr;   // frame address (relative or absolute)
    input [AXI_WR_ADDR_BITS-1:0] addr;         // command address (register to which command should be applied)
    input                 [31:0] data;         // command data
           
    reg [29:0] reg_addr;
    begin
        if (relative && (&frame_addr)) $display("task write_cmd_frame_sequencer(): relative address 'hf is invalid, it is reserved for module control");
        else begin
            reg_addr = CMDFRAMESEQ_ADDR_BASE + num_sensor * CMDFRAMESEQ_ADDR_INC + (relative ? CMDFRAMESEQ_REL : CMDFRAMESEQ_ABS) + frame_addr;
            write_contol_register(reg_addr, {{32-AXI_WR_ADDR_BITS{1'b0}}, addr});
            write_contol_register(reg_addr, data);
        end
    end
endtask
// x393_sensor.py
function [SENSOR_MODE_WIDTH-1:0] func_sensor_mode;
    input  [3:0] hist_en;    // [0..3] 1 - enable histogram modules, disable after processing the started frame
    input  [3:0] hist_nrst;  // [4..7] 0 - immediately reset histogram module 
    input        chn_en;     // [8]    1 - enable sensor channel (0 - reset) 
    input        bits16;     // [9]    0 - 8 bpp mode, 1 - 16 bpp (bypass gamma). Gamma-processed data is still used for histograms 
    reg  [SENSOR_MODE_WIDTH-1:0] tmp;
    begin
        tmp = 0;
        tmp [SENSOR_HIST_EN_BITS +: 4] =   hist_en;
        tmp [SENSOR_HIST_NRST_BITS +: 4] = hist_nrst;
        tmp [SENSOR_CHN_EN_BIT] =          chn_en;
        tmp [SENSOR_16BIT_BIT] =           bits16;
        func_sensor_mode = tmp;
    end
endfunction


// x393_sensor.py
function [31 : 0] func_sensor_i2c_command;
    input                                   rst_cmd;    // [14]   reset all FIFO (takes 16 clock pulses), also - stops i2c until run command
    input       [SENSI2C_CMD_RUN_PBITS : 0] run_cmd;    // [13:12]3 - run i2c, 2 - stop i2c (needed before software i2c), 1,0 - no change to run state
    input                                   set_active; 
    input                                   active_sda; 
    input                                   early_release_0; 
    
    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        tmp [SENSI2C_CMD_RESET] =                                 rst_cmd;
        tmp [SENSI2C_CMD_RUN  -: SENSI2C_CMD_RUN_PBITS+1] =       run_cmd;
        tmp [SENSI2C_CMD_ACIVE] =                                 set_active;
        tmp [SENSI2C_CMD_ACIVE_EARLY0] =                          active_sda;
        tmp [SENSI2C_CMD_ACIVE_SDA] =                             early_release_0;
        func_sensor_i2c_command = tmp;
    end
endfunction

function [27:0] func_sensor_i2c_table_reg_wr; //
    input                             [6:0] slave_addr; // 7-bit slave address
    input                             [7:0] rah;        // register address high byte
    input                             [3:0] num_bytes;  // number of bytes to send
    input                             [7:0] bit_delay;

    reg  [27 : 0] tmp;
    begin
        tmp = 0;
        tmp[SENSI2C_TBL_RAH +:  SENSI2C_TBL_RAH_BITS] =  rah;
        tmp[SENSI2C_TBL_RNWREG] =                        1'b0; // write register
        tmp[SENSI2C_TBL_SA +:   SENSI2C_TBL_SA_BITS] =   slave_addr;
        tmp[SENSI2C_TBL_NBWR +: SENSI2C_TBL_NBWR_BITS] = num_bytes;
        tmp[SENSI2C_TBL_DLY +:  SENSI2C_TBL_DLY_BITS] =  bit_delay;
        func_sensor_i2c_table_reg_wr =tmp;
    end
endfunction

function [27:0] func_sensor_i2c_table_reg_rd; //
    input                                   num_bytes_addr; // number of address bytes (0 - 1, 1 - 2)
    input                             [2:0] num_bytes_rd;  // number of bytes to read, with "0" meaning all 8
    input                             [7:0] bit_delay;

    reg  [27 : 0] tmp;
    begin
        tmp = 0;
        tmp[SENSI2C_TBL_RNWREG] =                        1'b1; // read register
        tmp[SENSI2C_TBL_NBRD +: SENSI2C_TBL_NBRD_BITS] = num_bytes_rd;
        tmp[SENSI2C_TBL_NABRD] =                         num_bytes_addr;
        tmp[SENSI2C_TBL_DLY +:  SENSI2C_TBL_DLY_BITS] =  bit_delay;
        func_sensor_i2c_table_reg_rd =tmp;
    end
endfunction



// x393_sensor.py
function                          [31 : 0] func_sensor_io_ctl;
    input                            [1:0] mrst;     // <2: keep MRST, 2 - MRST low (active),  3 - high (inactive)
    input                            [1:0] arst;     // <2: keep ARST, 2 - ARST low (active),  3 - high (inactive)
    input                            [1:0] aro;      // <2: keep ARO,  2 - set ARO (software controlled) low,  3 - set ARO  (software controlled) high
    input                            [1:0] mmcm_rst; // <2: keep MMCM reset, 2 - MMCM reset off,  3 - MMCM reset on
    input                            [1:0] clk_sel;  // <2: keep MMCM clock source, 2 - use internal pixel clock,  3 - use pixel clock from the sensor
    input                                  set_delays; // (self-clearing) load all pre-programmed delays 
    input                                  set_guadrants;  // 0 - keep quadrants settings, 1 - update quadrants
    input  [SENS_CTRL_QUADRANTS_WIDTH-1:0] quadrants;  // 90-degree shifts for data [1:0], hact [3:2] and vact [5:4]
    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        
        tmp [SENS_CTRL_MRST +: 2] =                               mrst;
        tmp [SENS_CTRL_ARST +: 2] =                               arst;
        tmp [SENS_CTRL_ARO  +: 2] =                               aro;
        tmp [SENS_CTRL_RST_MMCM  +: 2] =                          mmcm_rst;
        tmp [SENS_CTRL_EXT_CLK  +: 2] =                           clk_sel;
        tmp [SENS_CTRL_LD_DLY] =                                  set_delays;
        tmp [SENS_CTRL_QUADRANTS_EN] =                            set_guadrants;
        tmp [SENS_CTRL_QUADRANTS  +: SENS_CTRL_QUADRANTS_WIDTH] = quadrants;
        func_sensor_io_ctl = tmp;
    end
endfunction

// x393_sensor.py
function                          [31 : 0] func_sensor_jtag_ctl;
    input                            [1:0] pgmen;    // <2: keep PGMEN, 2 - PGMEN low (inactive),  3 - high (active) enable JTAG control
    input                            [1:0] prog;     // <2: keep prog, 2 - prog low (active),  3 - high (inactive) ("program" pin control)
    input                            [1:0] tck;      // <2: keep TCK,  2 - set TCK low,  3 - set TCK high
    input                            [1:0] tms;      // <2: keep TMS,  2 - set TMS low,  3 - set TMS high
    input                            [1:0] tdi;      // <2: keep TDI,  2 - set TDI low,  3 - set TDI high

    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        tmp [SENS_JTAG_PGMEN +: 2] = pgmen;
        tmp [SENS_JTAG_PROG +: 2] =  prog;
        tmp [SENS_JTAG_TCK +: 2] =   tck;
        tmp [SENS_JTAG_TMS +: 2] =   tms;
        tmp [SENS_JTAG_TDI +: 2] =   tdi;
        func_sensor_jtag_ctl = tmp;
    end
endfunction

// x393_sensor.py
function  [31 : 0] func_sensor_gamma_ctl;
    input   [1:0] bayer;
    input         table_page;
    input         en_input;
    input         repet_mode; //  Normal mode, single trigger - just for debugging  TODO: re-assign?
    input         trig;
    
    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        tmp[SENS_GAMMA_MODE_BAYER +: 2] = bayer;
        tmp [SENS_GAMMA_MODE_PAGE] =      table_page;
        tmp [SENS_GAMMA_MODE_EN] =        en_input;
        tmp [SENS_GAMMA_MODE_REPET] =     repet_mode;
        tmp [SENS_GAMMA_MODE_TRIG] =      trig;
        func_sensor_gamma_ctl =           tmp;
    end
endfunction

// ****************** compressor related tasks and functions *************************
// x393_cmprs.py
task compressor_control;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input [31:0] run_mode; // [2:0] < 0: nop, 0 - reset, 2 - run single from memory, 3 - run repetitive
    input [31:0] qbank;    // [6:3] quantization table page
    input [31:0] dc_sub;   // [8:7] subtract DC
    input [31:0] cmode;   //  [13:9] color mode:
//        parameter CMPRS_CBIT_CMODE_JPEG18 =   4'h0, // color 4:2:0
//        parameter CMPRS_CBIT_CMODE_MONO6 =    4'h1, // mono 4:2:0 (6 blocks)
//        parameter CMPRS_CBIT_CMODE_JP46 =     4'h2, // jp4, 6 blocks, original
//        parameter CMPRS_CBIT_CMODE_JP46DC =   4'h3, // jp4, 6 blocks, dc -improved
//        parameter CMPRS_CBIT_CMODE_JPEG20 =   4'h4, // mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
//        parameter CMPRS_CBIT_CMODE_JP4 =      4'h5, // jp4,  4 blocks, dc-improved
//        parameter CMPRS_CBIT_CMODE_JP4DC =    4'h6, // jp4,  4 blocks, dc-improved
//        parameter CMPRS_CBIT_CMODE_JP4DIFF =  4'h7, // jp4,  4 blocks, differential
//        parameter CMPRS_CBIT_CMODE_JP4DIFFHDR =  4'h8, // jp4,  4 blocks, differential, hdr
//        parameter CMPRS_CBIT_CMODE_JP4DIFFDIV2 = 4'h9, // jp4,  4 blocks, differential, divide by 2
//        parameter CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 4'ha, // jp4,  4 blocks, differential, hdr,divide by 2
//        parameter CMPRS_CBIT_CMODE_MONO1 =    4'hb, // mono JPEG (not yet implemented)
//        parameter CMPRS_CBIT_CMODE_MONO4 =    4'he, // mono 4 blocks
    input [31:0] multi_frame;   // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
    input [31:0] bayer;         // [20:18] // Bayer shift
    input [31:0] focus_mode;    // [23:21] Set focus mode
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        data = func_compressor_control (
            run_mode,       // [2:0] < 0: nop, 0 - reset, 2 - run single from memory, 3 - run repetitive
            qbank,          // [6:3] quantization table page
            dc_sub,         // [8:7] subtract DC
            cmode,          //  [13:9] color mode:
            multi_frame,    // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
            bayer,          // [20:18] // Bayer shift
            focus_mode);    // [23:21] Set focus mode
        reg_addr = (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC) + CMPRS_CONTROL_REG;
        write_contol_register(reg_addr, data);                   
    end
endtask

// x393_cmprs.py
task compressor_format;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input [31:0] num_macro_cols_m1; // number of macroblock colums minus 1
    input [31:0] num_macro_rows_m1; // number of macroblock rows minus 1
    input [31:0] left_margin;       // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        data = func_compressor_format (
            num_macro_cols_m1, // number of macroblock colums minus 1
            num_macro_rows_m1, // number of macroblock rows minus 1
            left_margin);       // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
        reg_addr = (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC) + CMPRS_FORMAT;
        write_contol_register(reg_addr, data);                   
    end
endtask

// x393_cmprs.py
task compressor_color_saturation;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input [31:0] colorsat_blue; //color saturation for blue (10 bits) //'h90 for 100%
    input [31:0] colorsat_red; //color saturation for red (10 bits)   // 'b6 for 100%
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        data = func_compressor_color_saturation (
            colorsat_blue, //color saturation for blue (10 bits) //'h90 for 100%
            colorsat_red); //color saturation for red (10 bits)  // 'b6 for 100%
        reg_addr = (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC) + CMPRS_COLOR_SATURATION;
        write_contol_register(reg_addr, data);                   
    end
endtask

// x393_cmprs.py
task compressor_coring;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input [31:0] coring;     // coring value
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        data = 0;
        data [CMPRS_CORING_BITS-1:0] = coring[CMPRS_CORING_BITS-1:0];
        reg_addr = (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC) + CMPRS_CORING_MODE;
        write_contol_register(reg_addr, data);                   
    end
endtask

task compressor_irq_en;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    input        en;         // 1 - enable, 0 - disable interrupts
    
    reg    [31:0] data;
    reg    [29:0] reg_addr;
    begin
        data = en? 3: 2;
        reg_addr = (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC) + CMPRS_INTERRUPTS;
        write_contol_register(reg_addr, data);                   
    end
endtask

task compressor_irq_clear;
    input [ 1:0] num_sensor; // sensor channel number (0..3)
    
    reg    [29:0] reg_addr;
    begin
        reg_addr = (CMPRS_GROUP_ADDR + num_sensor * CMPRS_BASE_INC) + CMPRS_INTERRUPTS;
        write_contol_register_irq(reg_addr, 1);                   
    end
endtask



// x393_cmprs.py
function [31 : 0] func_compressor_control;
    // argument <0 - NOP 
    input [31:0] run_mode; // [2:0] < 0: nop, 0 - reset, 2 - run single from memory, 3 - run repetitive
    input [31:0] qbank;    // [6:3] quantization table page
    input [31:0] dc_sub;   // [8:7] subtract DC
    input [31:0] cmode;   //  [13:9] color mode:
//        parameter CMPRS_CBIT_CMODE_JPEG18 =   4'h0, // color 4:2:0
//        parameter CMPRS_CBIT_CMODE_MONO6 =    4'h1, // mono 4:2:0 (6 blocks)
//        parameter CMPRS_CBIT_CMODE_JP46 =     4'h2, // jp4, 6 blocks, original
//        parameter CMPRS_CBIT_CMODE_JP46DC =   4'h3, // jp4, 6 blocks, dc -improved
//        parameter CMPRS_CBIT_CMODE_JPEG20 =   4'h4, // mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
//        parameter CMPRS_CBIT_CMODE_JP4 =      4'h5, // jp4,  4 blocks, dc-improved
//        parameter CMPRS_CBIT_CMODE_JP4DC =    4'h6, // jp4,  4 blocks, dc-improved
//        parameter CMPRS_CBIT_CMODE_JP4DIFF =  4'h7, // jp4,  4 blocks, differential
//        parameter CMPRS_CBIT_CMODE_JP4DIFFHDR =  4'h8, // jp4,  4 blocks, differential, hdr
//        parameter CMPRS_CBIT_CMODE_JP4DIFFDIV2 = 4'h9, // jp4,  4 blocks, differential, divide by 2
//        parameter CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 4'ha, // jp4,  4 blocks, differential, hdr,divide by 2
//        parameter CMPRS_CBIT_CMODE_MONO1 =    4'hb, // mono JPEG (not yet implemented)
//        parameter CMPRS_CBIT_CMODE_MONO4 =    4'he, // mono 4 blocks
    input [31:0] multi_frame;   // [15:14] 0 - single-frame buffer, 1 - multiframe video memory buffer
    input [31:0] bayer;         // [20:18] // Bayer shift
    input [31:0] focus_mode;    // [23:21] Set focus mode
    
    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        if (!run_mode[31])   tmp[CMPRS_CBIT_RUN  -:   CMPRS_CBIT_RUN_BITS + 1]   =  {1'b1, run_mode[CMPRS_CBIT_RUN_BITS - 1 : 0]};
        if (!qbank[31])      tmp[CMPRS_CBIT_QBANK -:  CMPRS_CBIT_QBANK_BITS + 1] =  {1'b1, qbank[CMPRS_CBIT_QBANK_BITS - 1 : 0]};
        if (!dc_sub[31])     tmp[CMPRS_CBIT_DCSUB -:  CMPRS_CBIT_DCSUB_BITS + 1] =  {1'b1, dc_sub[CMPRS_CBIT_DCSUB_BITS - 1 : 0]};
        if (!cmode[31])      tmp[CMPRS_CBIT_CMODE -:  CMPRS_CBIT_CMODE_BITS + 1] =  {1'b1, cmode[CMPRS_CBIT_CMODE_BITS - 1 : 0]};
        if (!multi_frame[31])tmp[CMPRS_CBIT_FRAMES -: CMPRS_CBIT_FRAMES_BITS + 1] = {1'b1, multi_frame[CMPRS_CBIT_FRAMES_BITS - 1 : 0]};
        if (!bayer[31])      tmp[CMPRS_CBIT_BAYER -:  CMPRS_CBIT_BAYER_BITS + 1] =  {1'b1, bayer[CMPRS_CBIT_BAYER_BITS - 1 : 0]};
        if (!focus_mode[31]) tmp[CMPRS_CBIT_FOCUS -:  CMPRS_CBIT_FOCUS_BITS + 1] =  {1'b1, focus_mode[CMPRS_CBIT_FOCUS_BITS - 1 : 0]};
        func_compressor_control = tmp;
    end
endfunction

// x393_cmprs.py
function [31 : 0] func_compressor_format;
    input [31:0] num_macro_cols_m1; // number of macroblock colums minus 1
    input [31:0] num_macro_rows_m1; // number of macroblock rows minus 1
    input [31:0] left_margin;       // left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        tmp[CMPRS_FRMT_MBCM1 +: CMPRS_FRMT_MBCM1_BITS] = num_macro_cols_m1[CMPRS_FRMT_MBCM1_BITS - 1 : 0];
        tmp[CMPRS_FRMT_MBRM1 +: CMPRS_FRMT_MBRM1_BITS] = num_macro_rows_m1[CMPRS_FRMT_MBRM1_BITS - 1 : 0];
        tmp[CMPRS_FRMT_LMARG +: CMPRS_FRMT_LMARG_BITS] = left_margin      [CMPRS_FRMT_LMARG_BITS - 1 : 0];
        func_compressor_format = tmp;
    end
endfunction

// x393_cmprs.py
function [31 : 0] func_compressor_color_saturation;
    input [31:0] colorsat_blue; //color saturation for blue (10 bits) //'h90 for 100%
    input [31:0] colorsat_red; //color saturation for red (10 bits)   // 'b6 for 100%
    reg  [31 : 0] tmp;
    begin
        tmp = 0;
        tmp[CMPRS_CSAT_CB +: CMPRS_CSAT_CB_BITS] = colorsat_blue[CMPRS_CSAT_CB_BITS - 1 : 0];
        tmp[CMPRS_CSAT_CR +: CMPRS_CSAT_CR_BITS] = colorsat_red [CMPRS_CSAT_CR_BITS - 1 : 0];
        func_compressor_color_saturation = tmp;
    end
endfunction

// axi_hp channels for the compressed image data
// x393_cmprs_afi.py
task afi_mux_program_status;
    input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                             // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                             // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
    input [1:0] chn_afi;
    input [1:0] mode;
    input [5:0] seq_num;
    reg   [29:0] reg_addr;
    begin
        reg_addr = CMPRS_GROUP_ADDR + (port_afi ? CMPRS_AFIMUX_RADDR1 : CMPRS_AFIMUX_RADDR0) + chn_afi;
        program_status (reg_addr,
                        CMPRS_AFIMUX_STATUS_CNTRL,
                        mode,
                        seq_num);
    end
endtask

// x393_cmprs_afi.py
task afi_mux_reset;
    input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                             // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                             // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
    input [3:0] rst_chn;
    reg  [29:0] reg_addr;
    begin
        reg_addr = CMPRS_GROUP_ADDR + (port_afi ? CMPRS_AFIMUX_RADDR1 : CMPRS_AFIMUX_RADDR0) + CMPRS_AFIMUX_RST;
        write_contol_register(reg_addr, {28'b0,rst_chn});                   
    end
endtask

// x393_cmprs_afi.py
task afi_mux_enable_chn;
    input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                             // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                             // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
    input [1:0] en_chn;  // channel number to enable/disable;
    input       en;
    reg  [29:0] reg_addr;
    reg [31:0] data;
    begin
        reg_addr = CMPRS_GROUP_ADDR + (port_afi ? CMPRS_AFIMUX_RADDR1 : CMPRS_AFIMUX_RADDR0) + CMPRS_AFIMUX_EN;
        data = 0;
        data[2 * en_chn +: 2] = {1'b1,en};
        write_contol_register(reg_addr,data);                   
    end
endtask

// x393_cmprs_afi.py
task afi_mux_enable;
    input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                             // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                             // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
    input       en;
    reg  [29:0] reg_addr;
    reg [31:0] data;
    begin
        reg_addr = CMPRS_GROUP_ADDR + (port_afi ? CMPRS_AFIMUX_RADDR1 : CMPRS_AFIMUX_RADDR0) + CMPRS_AFIMUX_EN;
        data = 0;
        data[2 * 4 +: 2] = {1'b1,en};
        write_contol_register(reg_addr,data);                   
    end
endtask

// x393_cmprs_afi.py
task afi_mux_mode_chn;
    input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                             // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                             // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
    input [1:0] chn;        // channel number to set mode for
    input [1:0] mode;
    reg  [29:0] reg_addr;
/*
mode == 0 - show EOF pointer, internal
mode == 1 - show EOF pointer, confirmed
mode == 2 - show current pointer, internal
mode == 3 - show current pointer, confirmed
each group of 4 bits per channel : bits [1:0] - select, bit[2] - sset (0 - nop), bit[3] - not used
 */    
    
    reg [31:0] data;
    begin
        reg_addr = CMPRS_GROUP_ADDR + (port_afi ? CMPRS_AFIMUX_RADDR1 : CMPRS_AFIMUX_RADDR0) + CMPRS_AFIMUX_MODE;
        data = 0;
        data[4 * chn +: 4] = {2'b01, mode};
        write_contol_register(reg_addr,data);                   
    end
endtask

// x393_cmprs_afi.py
task afi_mux_chn_start_length;
    input [0:0] port_afi;    // number of AFI port (0 - afi 1, 1 - afi2) // configuration controlled by the code. currently
                             // both AFI are used: ch0 - cmprs_afi_mux_1.0, ch1 - cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_2.0, ch3 - cmprs_afi_mux_2
                             // May be changed to ch0 - cmprs_afi_mux_1.0, ch1 -cmprs_afi_mux_1.1,
                             //  ch2 - cmprs_afi_mux_1.2, ch3 - cmprs_afi_mux_1.3
    input [ 1:0] chn;  // channel number to set mode for
    input [26:0] sa;   // start address in 32-byte chunks
    input [26:0] length;     // channel buffer length in 32-byte chunks

    reg  [29:0] reg_addr;
    begin
        reg_addr = CMPRS_GROUP_ADDR + (port_afi ? CMPRS_AFIMUX_RADDR1 : CMPRS_AFIMUX_RADDR0) + CMPRS_AFIMUX_SA_LEN + chn;
        write_contol_register(reg_addr  , {5'b0, sa});                   
        write_contol_register(reg_addr+4, {5'b0, length});                   
    end
endtask

// tasks related to debug ring
`ifdef DEBUG_RING
task program_status_debug;
    input [1:0] mode;
    input [5:0] seq_num;
    begin
        program_status (DEBUG_ADDR,
                        DEBUG_SET_STATUS,
                        mode,
                        seq_num);
    end
endtask
task debug_read_ring;
    input integer num32;

    reg    [5:0] seq_num;
    integer i;
    begin
        // load all shift registers from sources
        write_contol_register(DEBUG_ADDR + DEBUG_LOAD, 0); 
        for (i = 0; i < num32; i = i+1 ) begin
            read_status(DEBUG_STATUS_REG_ADDR);
            seq_num = (registered_rdata[STATUS_SEQ_SHFT+:6] ^ 6'h20) &'h3f; // &'h30;
            write_contol_register(DEBUG_ADDR + DEBUG_SHIFT_DATA, 0); 
            while (((registered_rdata[STATUS_SEQ_SHFT+:6] ^ 6'h20) &'h3f) == seq_num) begin
                read_status(DEBUG_STATUS_REG_ADDR);
            end
            read_status(DEBUG_READ_REG_ADDR);
            DEBUG_ADDRESS = i;
            DEBUG_DATA = registered_rdata;
            
            
        end
    
    
    end
endtask
`endif
/*
    reg  [31:0] DEBUG_DATA;
    integer     DEBUG_ADDRESS; 

*/
`include "includes/tasks_tests_memory.vh" // SuppressThisWarning VEditor - may be unused
`include "includes/x393_tasks_afi.vh" // SuppressThisWarning VEditor - may be unused
`include "includes/x393_tasks_mcntrl_en_dis_priority.vh"
`include "includes/x393_tasks_mcntrl_buffers.vh"
`include "includes/x393_tasks_pio_sequences.vh"
`include "includes/x393_tasks_mcntrl_timing.vh" // SuppressThisWarning VEditor - not used
`include "includes/x393_tasks_ps_pio.vh"
`include "includes/x393_tasks_status.vh"
`include "includes/x393_tasks01.vh"
`include "includes/x393_mcontr_encode_cmd.vh"

// Save sensor data written to memory
reg [3:0] CAPTURE_SENSORS = 0;
reg [3:0] CAPTURED_SENSORS = 0;
//reg [3:0] CAPTURE_SENSORS_D = 0;

//x393_i.pclk
//always @ (posedge x393_i.sensors393_i.sensor_channel_block[0].sensor_channel_i.pclk);
always @ (posedge x393_i.pclk or posedge RST_CLEAN) begin
    if (RST_CLEAN) CAPTURE_SENSORS <= 0;
    else           CAPTURE_SENSORS <= (~CAPTURED_SENSORS & x393_i.sensors393_i.sof_out_pclk) | (CAPTURE_SENSORS & ~x393_i.sensors393_i.eof_out_pclk) ;
    if (RST_CLEAN) CAPTURED_SENSORS <= 0;
    else           CAPTURED_SENSORS <= CAPTURED_SENSORS | (CAPTURE_SENSORS & x393_i.sensors393_i.eof_out_pclk);
//    if (RST_CLEAN) CAPTURE_SENSORS_D <= 0;
//    else     CAPTURE_SENSORS_D <= CAPTURE_SENSORS;
end


localparam WRITE_SENSOR_CHN0 = 0;
localparam WRITE_SENSOR_CHN1 = 1;
localparam WRITE_SENSOR_CHN2 = 2;
localparam WRITE_SENSOR_CHN3 = 3;
localparam CAPTURE_FOREVER = 0; // 1;
integer file_chn0,file_chn1,file_chn2,file_chn3;
initial begin
    @(posedge CAPTURE_SENSORS[WRITE_SENSOR_CHN0]);
    file_chn0 = $fopen("simulation_data/sensor_to_memory_0.dat","w");
    $display("capture chn0 file opened, CAPTURE_SENSORS[WRITE_SENSOR_CHN0]= %x @%t",CAPTURE_SENSORS[WRITE_SENSOR_CHN0], $time);
    while  (CAPTURE_SENSORS[WRITE_SENSOR_CHN0]) begin
        @(posedge x393_i.pclk);
        if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN0]) begin
//            $display("file_chn0 <= %x",x393_i.sensors393_i.px_data[WRITE_SENSOR_CHN0]);
            $fwrite(file_chn0," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN0   +: 8]);
            $fwrite(file_chn0," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN0+8 +: 8]);
            if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN0])
                $fwrite(file_chn0,"\n");
        end
    end
    if (CAPTURE_FOREVER) begin
        $fwrite(file_chn0,"\n");
        $display("capture chn0 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.pclk);
            if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN0]) begin
                $fwrite(file_chn0," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN0   +: 8]);
                $fwrite(file_chn0," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN0+8 +: 8]);
                if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN0])
                    $fwrite(file_chn0,"\n");
            end
        end

    end
    $fclose(file_chn0);
    $display("capture chn0 ended @%t",$time);
end

initial begin
    @(posedge CAPTURE_SENSORS[WRITE_SENSOR_CHN1]);
    file_chn1 = $fopen("simulation_data/sensor_to_memory_1.dat","w");
    $display("capture chn1 file opened, CAPTURE_SENSORS[WRITE_SENSOR_CHN1]= %x @%t",CAPTURE_SENSORS[WRITE_SENSOR_CHN1], $time);
    while  (CAPTURE_SENSORS[WRITE_SENSOR_CHN1]) begin
        @(posedge x393_i.pclk);
        if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN1]) begin
            $fwrite(file_chn1," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN1   +: 8]);
            $fwrite(file_chn1," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN1+8 +: 8]);
            if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN1])
                $fwrite(file_chn1,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_chn1,"\n");
        $display("capture chn1 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.pclk);
            if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN1]) begin
                $fwrite(file_chn1," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN1   +: 8]);
                $fwrite(file_chn1," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN1+8 +: 8]);
                if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN1])
                    $fwrite(file_chn1,"\n");
            end
        end

    end
    $fclose(file_chn1);
    $display("capture chn1 ended @%t",$time);
end

initial begin
    @(posedge CAPTURE_SENSORS[WRITE_SENSOR_CHN2]);
    file_chn2 = $fopen("simulation_data/sensor_to_memory_2.dat","w");
    $display("capture chn2 file opened, CAPTURE_SENSORS[WRITE_SENSOR_CHN2]= %x @%t",CAPTURE_SENSORS[WRITE_SENSOR_CHN2], $time);
    while  (CAPTURE_SENSORS[WRITE_SENSOR_CHN2]) begin
        @(posedge x393_i.pclk);
        if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN2]) begin
            $fwrite(file_chn2," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN2   +: 8]);
            $fwrite(file_chn2," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN2+8 +: 8]);
            if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN2])
                $fwrite(file_chn2,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_chn2,"\n");
        $display("capture chn2 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.pclk);
            if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN2]) begin
                $fwrite(file_chn2," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN2   +: 8]);
                $fwrite(file_chn2," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN2+8 +: 8]);
                if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN2])
                    $fwrite(file_chn2,"\n");
            end
        end

    end
    $fclose(file_chn2);
    $display("capture chn2 ended @%t",$time);
end

initial begin
    @(posedge CAPTURE_SENSORS[WRITE_SENSOR_CHN3]);
    file_chn3 = $fopen("simulation_data/sensor_to_memory_3.dat","w");
    $display("capture chn3 file opened, CAPTURE_SENSORS[WRITE_SENSOR_CHN3]= %x @%t",CAPTURE_SENSORS[WRITE_SENSOR_CHN3], $time);
    while  (CAPTURE_SENSORS[WRITE_SENSOR_CHN3]) begin
        @(posedge x393_i.pclk);
        if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN3]) begin
            $fwrite(file_chn3," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN3   +: 8]);
            $fwrite(file_chn3," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN3+8 +: 8]);
            if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN3])
                $fwrite(file_chn3,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_chn3,"\n");
        $display("capture chn3 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.pclk);
            if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN3]) begin
                $fwrite(file_chn3," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN3   +: 8]);
                $fwrite(file_chn3," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN3+8 +: 8]);
                if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN3])
                    $fwrite(file_chn3,"\n");
            end
        end

    end
    $fclose(file_chn3);
    $display("capture chn3 ended @%t",$time);
end

/*
initial begin
    @(posedge CAPTURE_SENSORS[WRITE_SENSOR_CHN]);
    file_chn = $fopen("sensor_to_memory.dat","w");
    $display("capture chn file opened, CAPTURE_SENSORS[WRITE_SENSOR_CHN]= %x @%t",CAPTURE_SENSORS[WRITE_SENSOR_CHN], $time);
    while  (CAPTURE_SENSORS[WRITE_SENSOR_CHN]) begin
        @(posedge x393_i.pclk);
        if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN]) begin
            $fwrite(file_chn," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN   +: 8]);
            $fwrite(file_chn," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN+8 +: 8]);
            if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN])
                $fwrite(file_chn,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_chn,"\n");
        $display("capture chn first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.pclk);
            if (x393_i.sensors393_i.px_valid[WRITE_SENSOR_CHN]) begin
                $fwrite(file_chn," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN   +: 8]);
                $fwrite(file_chn," %02x",x393_i.sensors393_i.px_data[16*WRITE_SENSOR_CHN+8 +: 8]);
                if (x393_i.sensors393_i.last_in_line[WRITE_SENSOR_CHN])
                    $fwrite(file_chn,"\n");
            end
        end

    end
    $fclose(file_chn);
    $display("capture chn ended @%t",$time);
end
*/
integer file_cmprs_chn0, file_cmprs_chn1, file_cmprs_chn2, file_cmprs_chn3;
localparam WRITE_COMPRESSOR_CHN0 = 0;
localparam WRITE_COMPRESSOR_CHN1 = 1;
localparam WRITE_COMPRESSOR_CHN2 = 2;
localparam WRITE_COMPRESSOR_CHN3 = 3;
reg [3:0] CAPTURE_COMPRESSORS = 0;
reg [3:0] CAPTURED_COMPRESSORS = 0;
reg [3:0] CAPTURE_COMPRESSORS_REN_D;
reg [3:0] CAPTURE_COMPRESSORS_REN_D2;
wire [3:0] CAPTURE_COMPRESSOR_START;
    pulse_cross_clock capture_compressor_start_0_i (.rst(RST_CLEAN), .src_clk(x393_i.mclk), .dst_clk(x393_i.hclk),
                                                    .in_pulse(x393_i.compressor393_i.frame_start_dst[0]), .out_pulse(CAPTURE_COMPRESSOR_START[0]),.busy());
    pulse_cross_clock capture_compressor_start_1_i (.rst(RST_CLEAN), .src_clk(x393_i.mclk), .dst_clk(x393_i.hclk),
                                                    .in_pulse(x393_i.compressor393_i.frame_start_dst[1]), .out_pulse(CAPTURE_COMPRESSOR_START[1]),.busy());
    pulse_cross_clock capture_compressor_start_2_i (.rst(RST_CLEAN), .src_clk(x393_i.mclk), .dst_clk(x393_i.hclk),
                                                    .in_pulse(x393_i.compressor393_i.frame_start_dst[2]), .out_pulse(CAPTURE_COMPRESSOR_START[2]),.busy());
    pulse_cross_clock capture_compressor_start_3_i (.rst(RST_CLEAN), .src_clk(x393_i.mclk), .dst_clk(x393_i.hclk),
                                                    .in_pulse(x393_i.compressor393_i.frame_start_dst[3]), .out_pulse(CAPTURE_COMPRESSOR_START[3]),.busy());

always @ (posedge x393_i.hclk or posedge RST_CLEAN) begin
    if (RST_CLEAN) CAPTURE_COMPRESSORS <= 0;
    else           CAPTURE_COMPRESSORS <= (~CAPTURED_COMPRESSORS & CAPTURE_COMPRESSOR_START) | (CAPTURE_COMPRESSORS & ~x393_i.compressor393_i.eof_written) ;
    
    if (RST_CLEAN) CAPTURED_COMPRESSORS <= 0;
    else           CAPTURED_COMPRESSORS <= CAPTURED_COMPRESSORS | (CAPTURE_COMPRESSORS & x393_i.compressor393_i.eof_written);
    
    if (RST_CLEAN) CAPTURE_COMPRESSORS_REN_D <= 0;
    else           CAPTURE_COMPRESSORS_REN_D <= x393_i.compressor393_i.fifo_ren;

    if (RST_CLEAN) CAPTURE_COMPRESSORS_REN_D2 <= 0;
    else           CAPTURE_COMPRESSORS_REN_D2 <= CAPTURE_COMPRESSORS_REN_D;
end

initial begin
    @(posedge CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN0]);
    file_cmprs_chn0 = $fopen("simulation_data/compressor_out_0.dat","w");
    $display("capture compressor chn0 file opened, CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN0]= %x @%t",CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN0], $time);
    while  (CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN0]) begin
        @(posedge x393_i.hclk);
        if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN0]) begin
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0      +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 +  8 +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 16 +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 24 +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 32 +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 40 +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 48 +: 8]);
            $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 56 +: 8]);
            $fwrite(file_cmprs_chn0,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_cmprs_chn0,"\n");
        $display("capture compressor chn0 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.hclk);
            if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN0]) begin
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0      +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 +  8 +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 16 +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 24 +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 32 +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 40 +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 48 +: 8]);
                $fwrite(file_cmprs_chn0," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN0 + 56 +: 8]);
                $fwrite(file_cmprs_chn0,"\n");
            end
        end

    end
    $fclose(file_cmprs_chn0);
    $display("capture compressor chn0 ended @%t",$time);
end
initial begin
    @(posedge CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN1]);
    file_cmprs_chn1 = $fopen("simulation_data/compressor_out_1.dat","w");
    $display("capture compressor chn1 file opened, CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN1]= %x @%t",CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN1], $time);
    while  (CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN1]) begin
        @(posedge x393_i.hclk);
        if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN1]) begin
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1      +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 +  8 +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 16 +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 24 +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 32 +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 40 +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 48 +: 8]);
            $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 56 +: 8]);
            $fwrite(file_cmprs_chn1,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_cmprs_chn1,"\n");
        $display("capture compressor chn1 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.hclk);
            if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN1]) begin
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1      +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 +  8 +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 16 +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 24 +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 32 +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 40 +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 48 +: 8]);
                $fwrite(file_cmprs_chn1," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN1 + 56 +: 8]);
                $fwrite(file_cmprs_chn1,"\n");
            end
        end

    end
    $fclose(file_cmprs_chn1);
    $display("capture compressor chn1 ended @%t",$time);
end
initial begin
    @(posedge CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN2]);
    file_cmprs_chn2 = $fopen("simulation_data/compressor_out_2.dat","w");
    $display("capture compressor chn2 file opened, CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN2]= %x @%t",CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN2], $time);
    while  (CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN2]) begin
        @(posedge x393_i.hclk);
        if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN2]) begin
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2      +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 +  8 +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 16 +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 24 +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 32 +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 40 +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 48 +: 8]);
            $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 56 +: 8]);
            $fwrite(file_cmprs_chn2,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_cmprs_chn2,"\n");
        $display("capture compressor chn2 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.hclk);
            if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN2]) begin
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2      +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 +  8 +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 16 +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 24 +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 32 +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 40 +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 48 +: 8]);
                $fwrite(file_cmprs_chn2," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN2 + 56 +: 8]);
                $fwrite(file_cmprs_chn2,"\n");
            end
        end

    end
    $fclose(file_cmprs_chn2);
    $display("capture compressor chn2 ended @%t",$time);
end
initial begin
    @(posedge CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN3]);
    file_cmprs_chn3 = $fopen("simulation_data/compressor_out_3.dat","w");
    $display("capture compressor chn3 file opened, CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN3]= %x @%t",CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN3], $time);
    while  (CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN3]) begin
        @(posedge x393_i.hclk);
        if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN3]) begin
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3      +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 +  8 +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 16 +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 24 +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 32 +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 40 +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 48 +: 8]);
            $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 56 +: 8]);
            $fwrite(file_cmprs_chn3,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_cmprs_chn3,"\n");
        $display("capture compressor chn3 first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.hclk);
            if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN3]) begin
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3      +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 +  8 +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 16 +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 24 +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 32 +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 40 +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 48 +: 8]);
                $fwrite(file_cmprs_chn3," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN3 + 56 +: 8]);
                $fwrite(file_cmprs_chn3,"\n");
            end
        end

    end
    $fclose(file_cmprs_chn3);
    $display("capture compressor chn3 ended @%t",$time);
end

/*
integer file_cmprs_chn;
localparam capture compressor chn0 = 0;
initial begin
    @(posedge CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN]);
    file_cmprs_chn = $fopen("compressor_out.dat","w");
    $display("capture compressor chn file opened, CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN]= %x @%t",CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN], $time);
    while  (CAPTURE_COMPRESSORS[WRITE_COMPRESSOR_CHN]) begin
        @(posedge x393_i.hclk);
        if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN]) begin
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN      +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN +  8 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 16 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 24 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 32 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 40 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 48 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 56 +: 8]);
            $fwrite(file_cmprs_chn,"\n");
        end
    end 
    if (CAPTURE_FOREVER) begin
        $fwrite(file_cmprs_chn,"\n");
        $display("capture chn first frame done, continue capturing @%t",$time);
        forever begin
            @(posedge x393_i.hclk);
        if (CAPTURE_COMPRESSORS_REN_D2[WRITE_COMPRESSOR_CHN]) begin
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN      +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN +  8 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 16 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 24 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 32 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 40 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 48 +: 8]);
            $fwrite(file_cmprs_chn," %x",x393_i.compressor393_i.fifo_rdata[64*WRITE_COMPRESSOR_CHN + 56 +: 8]);
            $fwrite(file_cmprs_chn,"\n");
        end
        end

    end
    $fclose(file_cmprs_chn);
    $display("capture compressor chn ended @%t",$time);
end
*/



endmodule

