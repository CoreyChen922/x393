  // This file may be used to define same pre-processor macros to be included into each parsed file
`ifndef SYSTEM_DEFINES
  `define SYSTEM_DEFINES
//`define MEMBRIDGE_DEBUG_READ 1
  `define use200Mhz 1
  `define USE_CMD_ENCOD_TILED_32_RD 1  
  // It can be used to check different `ifdef branches
  //`define XIL_TIMING //Simprim 
  `define den4096Mb 1
//  `define IVERILOG
  // defines for memory channels
  // chn 0 is read from memory and write to memory
 `define def_enable_mem_chn0
 `define def_read_mem_chn0
 `define def_write_mem_chn0
 //`define  def_scanline_chn0
 //`define  def_tiled_chn0
 
  // chn 1 is scanline r+w
 `define  def_enable_mem_chn1
 `define  def_read_mem_chn1
 `define  def_write_mem_chn1
 `define  def_scanline_chn1
 //`define   def_tiled_chn1

  // chn 2 is tiled r+w
 `define  def_enable_mem_chn2
 `define  def_read_mem_chn2
 `define  def_write_mem_chn2
 //`define   def_scanline_chn2
 `define  def_tiled_chn2

  // chn 3 is scanline r+w (reuse later)
 `define  def_enable_mem_chn3
 `define  def_read_mem_chn3
 `define  def_write_mem_chn3
 `define  def_scanline_chn3
 //`define   def_tiled_chn3

  // chn 4 is tiled r+w (reuse later)
 `define  def_enable_mem_chn4
 `define  def_read_mem_chn4
 `define  def_write_mem_chn4
 //`define   def_scanline_chn4
 `define  def_tiled_chn4

  // chn 5 is disabled
 //`define def_enable_mem_chn5

  // chn 6 is disabled
 //`define  def_enable_mem_chn6
 
  // chn 7 is disabled
 //`define  def_enable_mem_chn7
 
  // chn 8 is disabled
 //`define  def_enable_mem_chn8
 
  // chn 9 is disabled
 //`define  def_enable_mem_chn9
 
  // chn 10 is disabled
 //`define  def_enable_mem_chn10
 
  // chn 11 is disabled
 //`define  def_enable_mem_chn11
 
  // chn 12 is disabled
 //`define  def_enable_mem_chn12
 
  // chn 13 is disabled
 //`define  def_enable_mem_chn13
 
  // chn 14 is disabled
 //`define  def_enable_mem_chn14
 
  // chn 15 is disabled
 //`define  def_enable_mem_chn15
`endif
 
