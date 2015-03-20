from __future__ import print_function
'''
# Copyright (C) 2015, Elphel.inc.
# Methods that mimic Verilog tasks used for simulation  
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

@author:     Andrey Filippov
@copyright:  2015 Elphel, Inc.
@license:    GPLv3.0+
@contact:    andrey@elphel.coml
@deffield    updated: Updated
'''
__author__ = "Andrey Filippov"
__copyright__ = "Copyright 2015, Elphel, Inc."
__license__ = "GPL"
__version__ = "3.0+"
__maintainer__ = "Andrey Filippov"
__email__ = "andrey@elphel.com"
__status__ = "Development"
#import sys
#import x393_mem
#x393_pio_sequences
#from import_verilog_parameters import VerilogParameters
from x393_mem import X393Mem
from x393_axi_control_status import X393AxiControlStatus
from x393_mcntrl_buffers     import X393McntrlBuffers
#from verilog_utils import * # concat, bits 
from verilog_utils import concat, bits 
#from x393_axi_control_status import concat, bits
import vrlg # global parameters
class X393PIOSequences(object):
    DRY_MODE= True # True
    DEBUG_MODE=1
#    vpars=None
    x393_mem=None
    x393_axi_tasks=None #x393X393AxiControlStatus
    target_phase=0 # TODO: set!
    def __init__(self, debug_mode=1,dry_mode=True):
        self.DEBUG_MODE=debug_mode
        self.DRY_MODE=dry_mode
        self.x393_mem=X393Mem(debug_mode,dry_mode)
        self.x393_axi_tasks=X393AxiControlStatus(debug_mode,dry_mode)
        self.x393_mcntrl_buffers= X393McntrlBuffers(debug_mode,dry_mode)
#        self.__dict__.update(VerilogParameters.__dict__["_VerilogParameters__shared_state"]) # Add verilog parameters to the class namespace
        '''
        Maybe import parameters into the module, not class namespace to use directly, w/o self. ?
#        __dict__.update(VerilogParameters.__dict__) # Add verilog parameters to the class namespace
        '''
        
    def schedule_ps_pio(self,          #; // schedule software-control memory operation (may need to check FIFO status first)
                        seq_addr,      # input [9:0] seq_addr; // sequence start address
                        page,          # input [1:0] page;     // buffer page number
                        urgent,        # input       urgent;   // high priority request (only for competion wityh other channels, wiil not pass in this FIFO)
                        chn,           # input       chn;      // channel buffer to use: 0 - memory read, 1 - memory write
                        wait_complete): # input       wait_complete; // Do not request a newe transaction from the scheduler until previous memory transaction is finished
        """
        Schedule PS PIO memory transaction 
        <seq_addr>       10-bit sequence start address
        <page>           buffer page address to use (0..3)
        <urgent>         high priority request (only for competition with other channels,
                         will not pass other commands in this module FIFO)  
        <chn>            sub-channel to use: 0 - memory read, 1 - memory write
        <wait_complete>  Do not request a new transaction from the scheduler until previous memory transaction is finished
        """
        self.x393_axi_tasks.write_contol_register(vrlg.MCNTRL_PS_ADDR + vrlg.MCNTRL_PS_CMD,
                                                  # {17'b0,
                                                  ((0,1)[wait_complete]<<14) |
                                                  ((0,1)[chn]<<13) |
                                                  ((0,1)[urgent]<<12) |
                                                  ((page & 3) << 10) |
                                                  (seq_addr & 0x3ff))
 
    def wait_ps_pio_ready(self,         #; // wait PS PIO module can accept comamnds (fifo half empty)
                          mode,         # input [1:0] mode;
                          sync_seq,     # input       sync_seq; //  synchronize sequences
                          timeout=2.0): # maximal timeout in seconds
        """
        Wait until PS PIO module can accept comamnds (fifo half empty) 
        <mode>           status mode (0..3) - see 'help program_status'
        <synq_seq>       status sequence number - see 'help program_status'
        """
        
        self.x393_axi_tasks.wait_status_condition (
            vrlg.MCNTRL_PS_STATUS_REG_ADDR,
            vrlg.MCNTRL_PS_ADDR + vrlg.MCNTRL_PS_STATUS_CNTRL,
            mode & 3,
            0,
            2 << vrlg.STATUS_2LSB_SHFT,
            0,
            sync_seq)

    def wait_ps_pio_done(self,         # // wait PS PIO module has no pending/running memory transaction
                         mode,         # input [1:0] mode;
                         sync_seq,     # input       sync_seq; //  synchronize sequences
                         timeout=2.0): # maximal timeout in seconds
        """
        Wait PS PIO module has no pending/running memory transaction
        <mode>           status mode (0..3) - see 'help program_status'
        <synq_seq>       status sequence number - see 'help program_status'
        """
        self.x393_axi_tasks.wait_status_condition (
            vrlg.MCNTRL_PS_STATUS_REG_ADDR,
            vrlg.MCNTRL_PS_ADDR + vrlg.MCNTRL_PS_STATUS_CNTRL,
            mode & 3,
            0,
            3 << vrlg.STATUS_2LSB_SHFT,
            0,
            sync_seq,
            timeout)
    '''
    x393_mcontr_encode_cmd
    '''
    def func_encode_cmd(self,      # function [31:0] 
                        addr,      # input               [14:0] addr;       // 15-bit row/column adderss
                        bank,      # input                [2:0] bank;       // bank (here OK to be any)
                        rcw,       # input                [2:0] rcw;        // RAS/CAS/WE, positive logic
                        odt_en,    # input                      odt_en;     // enable ODT
                        cke,       # input                      cke;        // disable CKE
                        sel,       # input                      sel;        // first/second half-cycle, other will be nop (cke+odt applicable to both)
                        dq_en,     # input                      dq_en;      // enable (not tristate) DQ  lines (internal timing sequencer for 0->1 and 1->0)
                        dqs_en,    # input                      dqs_en;     // enable (not tristate) DQS lines (internal timing sequencer for 0->1 and 1->0)
                        dqs_toggle,# input                      dqs_toggle; // enable toggle DQS according to the pattern
                        dci,       # input                      dci;        // DCI disable, both DQ and DQS lines (internal logic and timing sequencer for 0->1 and 1->0)
                        buf_wr,    # input                      buf_wr;     // connect to external buffer (but only if not paused)
                        buf_rd,    # input                      buf_rd;     // connect to external buffer (but only if not paused)
                        nop,       # input                      nop;        // add NOP after the current command, keep other data
                        buf_rst):  # input                      buf_rst;    // connect to external buffer (but only if not paused)
        """
        Encode data into memory controller sequencer word
        <addr>       15-bit row/column adderss
        <bank>       3-bit bank address
        <rcw>        3-bit combined {RAS,CAS,WE}, positive logic
        <odt_en>     enable ODT
        <cke>        disable CKE
        <sel>        first(0)/second(1) half-cycle, other half-cycle will be NOP (cke+odt applicable to both)
        <dq_en>      enable (turn tristate off) DQ  lines (internal timing sequencer for 0->1 and 1->0)
        <dqs_en>     enable (turn tristate off) DQS lines (internal timing sequencer for 0->1 and 1->0)
        <dqs_toggle> enable toggle DQS lines according to the pattern
        <dci>        DCI disable, both DQ and DQS lines (internal logic and timing sequencer for 0->1 and 1->0)
        <buf_wr>     generate external buffer write/address increment
        <buf_rd>     generate external buffer read/address increment
        <nop>        add NOP after the current command, keep other data
        <buf_rst>    reset external buffer page address to 0, increment page number
        """
        return (
            ((addr & 0x7fff) << 17) | # addr[14:0], // 15-bit row/column adderss
            ((bank & 0x7)    << 14) | # bank [2:0], // bank
            ((rcw  & 0x7)    << 11) | # rcw[2:0],   // RAS/CAS/WE
            ((0,1)[odt_en]   << 10) | # odt_en,     // enable ODT
            ((0,1)[cke]      <<  9) | # cke,        // may be optimized (removed from here)?
            ((0,1)[sel]      <<  8) | # sel,        // first/second half-cycle, other will be nop (cke+odt applicable to both)
            ((0,1)[dq_en]    <<  7) | # dq_en,      // enable (not tristate) DQ  lines (internal timing sequencer for 0->1 and 1->0)
            ((0,1)[dqs_en]   <<  6) | # dqs_en,     // enable (not tristate) DQS  lines (internal timing sequencer for 0->1 and 1->0)
            ((0,1)[dqs_toggle]<< 5) | # dqs_toggle, // enable toggle DQS according to the pattern
            ((0,1)[dci]      <<  4) | # dci,        // DCI disable, both DQ and DQS lines (internal logic and timing sequencer for 0->1 and 1->0)
            ((0,1)[buf_wr]   <<  3) | # buf_wr,     // phy_buf_wr,   // connect to external buffer (but only if not paused)
            ((0,1)[buf_rd]   <<  2) | # buf_rd,     // phy_buf_rd,    // connect to external buffer (but only if not paused)
            ((0,1)[nop]      <<  1) | # nop,        // add NOP after the current command, keep other data
            ((0,1)[buf_rst]  <<  0)   # buf_rst     // Reset buffer address/ increase buffer page
           )

    def func_encode_skip(self,       # function [31:0]
                          skip,       # input [CMD_PAUSE_BITS-1:0] skip;       // number of extra cycles to skip (and keep all the other outputs)
                          done,       # input                      done;       // end of sequence 
                          bank,       # input [2:0]                bank;       // bank (here OK to be any)
                          odt_en,     # input                      odt_en;     // enable ODT
                          cke,        # input                      cke;        // disable CKE
                          sel,        # input                      sel;        // first/second half-cycle, other will be nop (cke+odt applicable to both)
                          dq_en,      # input                      dq_en;      // enable (not tristate) DQ  lines (internal timing sequencer for 0->1 and 1->0)
                          dqs_en,     # input                      dqs_en;     // enable (not tristate) DQS lines (internal timing sequencer for 0->1 and 1->0)
                          dqs_toggle, # input                      dqs_toggle; // enable toggle DQS according to the pattern
                          dci,        # input                      dci;        // DCI disable, both DQ and DQS lines (internal logic and timing sequencer for 0->1 and 1->0)
                          buf_wr,     # input                      buf_wr;     // connect to external buffer (but only if not paused)
                          buf_rd,     # input                      buf_rd;     // connect to external buffer (but only if not paused)
                          buf_rst):   #input                       buf_rst;    // connect to external buffer (but only if not paused)
        """
        Encode skip cycles command into memory controller sequencer word. NOP will be present on RCW(RAS/CAS/WE) lines
        <skip>       10-bit number of cycles to skip minus 1
        <done>       10-bit number of cycles to skip minus 1
        <bank>       3-bit bank address
        <odt_en>     enable ODT
        <cke>        disable CKE
        <sel>        first(0)/second(1) half-cycle, other half-cycle will be NOP (cke+odt applicable to both)
        <dq_en>      enable (turn tristate off) DQ  lines (internal timing sequencer for 0->1 and 1->0)
        <dqs_en>     enable (turn tristate off) DQS lines (internal timing sequencer for 0->1 and 1->0)
        <dqs_toggle> enable toggle DQS lines according to the pattern
        <dci>        DCI disable, both DQ and DQS lines (internal logic and timing sequencer for 0->1 and 1->0)
        <buf_wr>     generate external buffer write/address increment
        <buf_rd>     generate external buffer read/address increment
        <buf_rst>    reset external buffer page address to 0, increment page number
        """
        return self.func_encode_cmd (
                ((0,1)[done] << vrlg.CMD_PAUSE_BITS) |    # {{14-CMD_DONE_BIT{1'b0}}, done, 
                (skip & ((1 << vrlg.CMD_PAUSE_BITS)-1)), # skip[CMD_PAUSE_BITS-1:0]},       // 15-bit row/column address
                bank & 7,   # bank[2:0],  // bank (here OK to be any)
                0,          # 3'b0,       // RAS/CAS/WE, positive logic
                odt_en,     #// enable ODT
                cke,        #// disable CKE
                sel,        #// first/second half-cycle, other will be nop (cke+odt applicable to both)
                dq_en,      #// enable (not tristate) DQ  lines (internal timing sequencer for 0->1 and 1->0)
                dqs_en,     #// enable (not tristate) DQS lines (internal timing sequencer for 0->1 and 1->0)
                dqs_toggle, #// enable toggle DQS according to the pattern
                dci,        #// DCI disable, both DQ and DQS lines (internal logic and timing sequencer for 0->1 and 1->0)
                buf_wr,     #// connect to external buffer (but only if not paused)
                buf_rd,     #// connect to external buffer (but only if not paused)
                0,          # 1'b0,       // nop
                buf_rst)    #
        
    def func_ddr3_mr0(self, # ; # function [ADDRESS_NUMBER+2:0]
                      pd, # input       pd; // precharge power down 0 - dll off (slow exit), 1 - dll on (fast exit) 
                      wr, # input [2:0] wr; // write recovery:
                          # 3'b000: 16
                          # 3'b001:  5
                          # 3'b010:  6
                          # 3'b011:  7
                          # 3'b100:  8
                          # 3'b101: 10
                          # 3'b110: 12
                          # 3'b111: 14
                      dll_rst,  # input       dll_rst; // 1 - dll reset (self clearing bit)
                      cl, # input [3:0] cl; // CAS latency (>=15ns):
                          # 0000: reserved                   
                          # 0010:  5                   
                          # 0100:  6                   
                          # 0110:  7                 
                          # 1000:  8                 
                          # 1010:  9                 
                          # 1100: 10                   
                          # 1110: 11                   
                          # 0001: 12                  
                          # 0011: 13                  
                          # 0101: 14
                      bt, #input       bt; # read burst type: 0 sequential (nibble), 1 - interleaved
                      bl):  #input [1:0] bl; # burst length:
        #                   2'b00 - fixed BL8
        #                   2'b01 - 4 or 8 on-the-fly by A12                                     
        #                   2'b10 - fixed BL4 (chop)
        #                   2'b11 - reserved
        """
        Encode DDR3 MR0 register data
        <pd>  precharge power down 0 - dll off (slow exit), 1 - dll on (fast exit) 
        <wr>  write recovery:
            000: 16
            001:  5
            010:  6
            011:  7
            100:  8
            101: 10
            110: 12
            111: 14
        <dll_rst> 1 - dll reset (self clearing bit)
        <cl> CAS latency (>=15ns):
            0000: reserved                   
            0010:  5                   
            0100:  6                   
            0110:  7                 
            1000:  8                 
            1010:  9                 
            1100: 10                   
            1110: 11                   
            0001: 12                  
            0011: 13                  
            0101: 14
        <bt>  read burst type: 0 sequential (nibble), 1 - interleaved
        <bl>  burst length:
            00 - fixed BL8
            01 - 4 or 8 on-the-fly by A12                                     
            10 - fixed BL4 (chop)
            11 - reserved
        """
        
        return concat((
              (0,3),                      # 3'b0,
              (0,vrlg.ADDRESS_NUMBER-13), #  {ADDRESS_NUMBER-13{1'b0}},
              (pd,1),              # pd,       # MR0.12 
              (wr,3),                     # wr,       # MR0.11_9
              (dll_rst,1),                # dll_rst,  # MR0.8
              (0,1),                      # 1'b0,     # MR0.7
              (cl>>1,3),                  # cl[3:1],  # MR0.6_4
              (bt,1),                     # bt,       # MR0.3
              (cl&1,1),                   # cl[0],    # MR0.2
              (bl,2)))[0]                 # bl[1:0]}; # MR0.1_0

    def func_ddr3_mr1(self, # function [ADDRESS_NUMBER+2:0] 
                      qoff, # input       qoff; # output enable: 0 - DQ, DQS operate in normal mode, 1 - DQ, DQS are disabled
                      tdqs, # input       tdqs; # termination data strobe (for x8 devices) 0 - disabled, 1 - enabled
                      rtt,  # input [2:0] rtt;  # on-die termination resistance:
                          #  3'b000 - disabled
                          #  3'b001 - RZQ/4 (60 Ohm)
                          #  3'b010 - RZQ/2 (120 Ohm)
                          #  3'b011 - RZQ/6 (40 Ohm)
                          #  3'b100 - RZQ/12(20 Ohm)
                          #  3'b101 - RZQ/8 (30 Ohm)
                          #  3'b11x - reserved
                      wlev, #input       wlev; # write leveling
                      ods, # input [1:0] ods;  # output drive strength:
                          #  2'b00 - RZQ/6 - 40 Ohm
                          #  2'b01 - RZQ/7 - 34 Ohm
                          #  2'b1x - reserved
                      al, # input [1:0] al;   # additive latency:
                          #  2'b00 - disabled (AL=0)
                          #  2'b01 - AL=CL-1;
                          #  2'b10 - AL=CL-2
                          #  2'b11 - reserved
                      dll): #input       dll;  # 0 - DLL enabled (normal), 1 - DLL disabled
        """
        Encode DDR3 MR1 register data
        <qoff>  output enable: 0 - DQ, DQS operate in normal mode, 1 - DQ, DQS are disabled
        <tdqs>  termination data strobe (for x8 devices) 0 - disabled, 1 - enabled
        <rtt>   on-die termination resistance:
            000 - disabled
            001 - RZQ/4 (60 Ohm)
            010 - RZQ/2 (120 Ohm)
            011 - RZQ/6 (40 Ohm)
            100 - RZQ/12(20 Ohm)
            101 - RZQ/8 (30 Ohm)
            11x - reserved
        <wlev>  write leveling mode
        <ods>   output drive strength:
            00 - RZQ/6 - 40 Ohm
            01 - RZQ/7 - 34 Ohm
            1x - reserved
        <al>    additive latency:
            00 - disabled (AL=0)
            01 - AL=CL-1;
            10 - AL=CL-2
            11 - reserved
        <dll>   0 - DLL enabled (normal), 1 - DLL disabled
        """ 
        return concat (( #    ddr3_mr1 = {
              (1,3), # 3'h1,
              (0, vrlg.ADDRESS_NUMBER-13), # {ADDRESS_NUMBER-13{1'b0}},
              (qoff,1),                    # qoff,       # MR1.12 
              (tdqs,1),                    # tdqs,       # MR1.11
              (0,1),                       # 1'b0,       # MR1.10
              (rtt>>2,1),                  # rtt[2],     # MR1.9
              (0,1),                       # 1'b0,       # MR1.8
              (wlev,1),                    # wlev,       # MR1.7 
              (rtt>>1,1),                  # rtt[1],     # MR1.6 
              (ods>>1,1),                  # ods[1],     # MR1.5 
              (al,2),                      # al[1:0],    # MR1.4_3 
              (rtt,1),                     # rtt[0],     # MR1.2 
              (ods,1),                     # ods[0],     # MR1.1 
              (dll,1)))[0]                 #dll};       # MR1.0 
    
    def func_ddr3_mr2(self, # ; function [ADDRESS_NUMBER+2:0] 
                        rtt_wr, # input [1:0] rtt_wr; # Dynamic ODT :
                        #  2'b00 - disabled
                        #  2'b01 - RZQ/4 = 60 Ohm
                        #  2'b10 - RZQ/2 = 120 Ohm
                        #  2'b11 - reserved
                        srt,  # input       srt;    # Self-refresh temperature 0 - normal (0-85C), 1 - extended (<=95C)
                        asr,  # input       asr;    # Auto self-refresh 0 - disabled (manual), 1 - enabled (auto)
                        cwl): # input [2:0] cwl;    # CAS write latency:
                        #  3'b000  5CK (           tCK >= 2.5ns)  
                        #  3'b001  6CK (1.875ns <= tCK < 2.5ns)  
                        #  3'b010  7CK (1.5ns   <= tCK < 1.875ns)  
                        #  3'b011  8CK (1.25ns  <= tCK < 1.5ns)  
                        #  3'b100  9CK (1.071ns <= tCK < 1.25ns)  
                        #  3'b101 10CK (0.938ns <= tCK < 1.071ns)  
                        #  3'b11x reserved
        """                
        Encode DDR3 MR2 register data
        <rtt_wr>  Dynamic ODT :
            00 - disabled
            01 - RZQ/4 = 60 Ohm
            10 - RZQ/2 = 120 Ohm
            11 - reserved
        <srt>     Self-refresh temperature 0 - normal (0-85C), 1 - extended (<=95C)
        <asr>     Auto self-refresh 0 - disabled (manual), 1 - enabled (auto)
        <cwl>     CAS write latency:
            000  5CK (           tCK >= 2.5ns)  
            001  6CK (1.875ns <= tCK < 2.5ns)  
            010  7CK (1.5ns   <= tCK < 1.875ns)  
            011  8CK (1.25ns  <= tCK < 1.5ns)  
            100  9CK (1.071ns <= tCK < 1.25ns)  
            101 10CK (0.938ns <= tCK < 1.071ns)  
            11x reserved
        """ 
        return concat ((                  
                (2,3),                       #   3'h2,
                (0, vrlg.ADDRESS_NUMBER-11), # {ADDRESS_NUMBER-11{1'b0}},
                (rtt_wr,2),                  # rtt_wr[1:0], # MR2.10_9
                (0,1),                       # 1'b0,        # MR2.8
                (srt,1),                     # srt,         # MR2.7
                (asr,1),                     # asr,         # MR2.6
                (cwl,3),                     # cwl[2:0],    # MR2.5_3
                (0,3)))[0]                   # 3'b0};       # MR2.2_0 

    def func_ddr3_mr3(self,       # function [ADDRESS_NUMBER+2:0]
                      mpr,        # input       mpr;    # MPR mode: 0 - normal, 1 - dataflow from MPR
                      mpr_rf):    # input [1:0] mpr_rf; # MPR read function:
                            #  2'b00: predefined pattern 0101...
                            #  2'b1x, 2'bx1 - reserved
        """                
        Encode DDR3 MR3 register data
        <mpr>      MPR mode: 0 - normal, 1 - dataflow from MPR
        <mpr_rf>   MPR read function:
            00: predefined pattern 0101...
            1x, 2'bx1 - reserved
        """ 
        return concat((
                (3,3),                     # 3'h3,
                (0,vrlg.ADDRESS_NUMBER-3), # {ADDRESS_NUMBER-3{1'b0}},
                (mpr, 1),                  # mpr,          # MR3.2
                (mpr_rf,2)))[0]            # mpr_rf[1:0]}; # MR3.1_0 
        
    '''
    x393_tasks_pio_sequences
    '''
    def enable_reset_ps_pio(self, #; // control reset and enable of the PS PIO channel;
                            en,   # input en;
                            rst): #input rst;
        """
        Enable/disable and reset PS PIO channel
        <en>   1 - enable, 0 - disable (only influences request for arbitration, started transactions will finish if disabled)
        <rst>  1 - reset active, 0 - reset off
        """
        
        self.x393_axi_tasks.write_contol_register(vrlg.MCNTRL_PS_ADDR + vrlg.MCNTRL_PS_EN_RST,
                                   ((0,1)[en]<<1) | #{30'b0,en,
                                   (1,0)[rst])  #~rst});
   
   
    def set_read_block(self, #
                       ba,   # input [ 2:0] ba;
                       ra,   # input [14:0] ra;
                       ca,  #input [ 9:0] ca;
                       verbose=0):
        """
        Setup read block sequence at parameter defined address in the sequencer memory
        <ba>   3-bit memory bank address
        <ra>  15-bit memory row address
        <ca>  10-bit memory column address
        <verbose> print data being written (default: False)
            
        """
        cmd_addr = vrlg.MCONTR_CMD_WR_ADDR + vrlg.READ_BLOCK_OFFSET
# activate
        #                           addr                bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(  ra,                  ba,      4,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# see if pause is needed . See when buffer read should be started - maybe before WR command
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 1,       0,          0,           0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr+=1
# first read
# read
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(ca&0x3ff,              ba,      2,  0,  0,  1,  0,    0,    0,    1,  1,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 0,       0,          ba,          0,  0,  1,  0,    0,    0,    1,  1,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
#repeat remaining reads             
        for i in range(1,64):
# read
#                                  addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
            data=self.func_encode_cmd((ca & 0x3ff)+(i<<3),ba,     2,  0,  0,  1,  0,    0,    0,    1,  1,   0,   1,   0)
            self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
            cmd_addr += 1
# nop - all 3 below are the same? - just repeat?
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,       0,         ba,          0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,       0,         ba,          0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,       0,         ba,          0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# tRTP = 4*tCK is already satisfied, no skip here
# precharge, end of a page (B_RST)         
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(  ra,                  ba,      5,  0,  0,  0,  0,    0,    0,    1,  0,   0,   0,   1)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  2,       0,         0,           0,  0,  0,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Turn off DCI, set DONE
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,       1,         0,           0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1

    def set_write_block(self,#):
                        ba,  # input[2:0]ba;
                        ra,  # input[14:0]ra;
                        ca,  # input[9:0]ca;
                        num8=64,
                        extraTgl=0, #
                        verbose=0):

        """
        Setup write block sequence at parameter defined address in the sequencer memory
        <ba>   3-bit memory bank address
        <ra>  15-bit memory row address
        <ca>  10-bit memory column address
        <num8> - number of 8-bursts (default=64, should be >2)
        <verbose> print data being written (default: False)
        """
        print("===set_write_block ba=0x%x, ra=0x%x, ca=0x%x"%(ba,ra,ca))
        cmd_addr = vrlg.MCONTR_CMD_WR_ADDR + vrlg.WRITE_BLOCK_OFFSET
# activate
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd( ra,                   ba,      4,  0,  0,  0,  0,    0,    0,    0,  0,   1,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# see if pause is needed . See when buffer read should be started - maybe before WR command
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 1,       0,          0,           0,  0,  0,  0,    0,    0,    0,  0,   1,        0) # tRCD - 2 read bufs
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# first write, 3 rd_buf
# write
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(ca&0x3ff,              ba,      3,  1,  0,  1,  0,    0,    0,    0,  0,   1,   0,   0) # B_RD moved 1 cycle earlier 
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop 4-th rd_buf
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 0,       0,          ba,          1,  0,  0,  1,    1,    0,    0,  0,   1,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
#repeat remaining writes
        for i in range(1,num8-2): # 62) : #(i = 1; i < 62; i = i + 1) begin
# write
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
            data=self.func_encode_cmd((ca&0x3ff)+(i<<3), ba,      3,  1,  0,  1,  1,    1,    1,    0,  0,   1,   1,   0) 
            self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
            cmd_addr += 1
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
#        data=self.func_encode_cmd((ca&0x3ff)+(62<<3),    ba,      3,  1,  0,  1,  1,    1,    1,    0,  0,   1,   0,   0) # write w/o nop
        data=self.func_encode_cmd((ca&0x3ff)+((num8-2)<<3), ba,    3,  1,  0,  1,  1,    1,    1,    0,  0,   1,   0,   0) # write w/o nop
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
#nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 0,       0,          ba,          1,  0,  1,  1,    1,    1,    0,  0,   0,        0) # nop with buffer read off
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        
# One last write pair w/o buffer
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
#        data=self.func_encode_cmd((ca&0x3ff)+(63<<3),    ba,      3,  1,  0,  1,  1,    1,    1,    0,  0,   0,   1,   0) # write with nop
        data=self.func_encode_cmd((ca&0x3ff)+((num8-1)<<3),ba,     3,  1,  0,  1,  1,    1,    1,    0,  0,   0,   1,   0) # write with nop
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 0,       0,          ba,          1,  0,  0,  1,    1,    1,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 0,       0,          ba,          1,  0,  0,  1,    1,    1,    0,  0,   0,        1) # removed B_RD 1 cycle earlier
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( extraTgl,       0,          ba,          1,  0,  0,  1,    1,    1,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# ODT off, it has latency
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 2,       0,          ba,          0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# precharge, ODT off
        #                          addr                 bank     RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(  ra,                  ba,      5,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 2,       0,          ba,          0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Finalize, set DONE        
        #                          skip     done        bank         ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 0,       1,          0,           0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1

# Set MR3, read nrep*8 words, save to buffer (port0). No ACTIVATE/PRECHARGE are needed/allowed   
    def set_read_pattern (self, 
                          nrep, # input integer nrep;
                          verbose=0):
                          
        """
        Setup read pattern sequence at parameter defined address in the sequencer memory
        <nrep>   number of times pattern burst is read
        <verbose> print data being written (default: False)
            
        """
        
        cmd_addr = vrlg.MCONTR_CMD_WR_ADDR + vrlg.READ_PATTERN_OFFSET
        mr3_norm = self.func_ddr3_mr3(
           0, # 1'h0,     //       mpr;    // MPR mode: 0 - normal, 1 - dataflow from MPR
           0) # 2'h0);    // [1:0] mpr_rf; // MPR read function: 2'b00: predefined pattern 0101...
        mr3_patt = self.func_ddr3_mr3(
           1, # 1'h1,     //       mpr;    // MPR mode: 0 - normal, 1 - dataflow from MPR
           0) # 2'h0);    // [1:0] mpr_rf; // MPR read function: 2'b00: predefined pattern 0101...
# Set pattern mode
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr3_patt,(14,0)), bits(mr3_patt,(17,15)), 7,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 5,        0,           0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0)# tMOD
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# first read
#@ read
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(    0,                   0,                    2,  0,  0,  1,  0,    0,    0,    1,  1,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop (combine with previous?)
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       0,          0,                        0,  0,  1,  0,    0,    0,    1,  1,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
#repeat remaining reads
#        for (i = 1; i < nrep; i = i + 1) begin
        for _ in range(1,nrep):
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
            data=self.func_encode_cmd( 0,                  0,                    2,  0,  0,  1,  0,    0,    0,    1,  1,   0,   1,   0)
            self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
            cmd_addr += 1
# nop - all 3 below are the same? - just repeat?
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       0,          0,                        0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       0,          0,                        0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       0,          0,                        0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# nop, no write buffer - next page
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       0,          0,                        0,  0,  1,  0,    0,    0,    1,  0,   0,        1)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   1,       0,          0,                        0,  0,  1,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Turn off read pattern mode
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr3_norm,(14,0)), bits(mr3_norm,(17,15)), 7,  0,  0,  0,  0,    0,    0,    1,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# tMOD (keep DCI enabled)
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   5,       0,          0,                        0,  0,  0,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Turn off DCI
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       0,          0,                        0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Finalize (set DONE)
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(   0,       1,          0,                        0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1

    def set_write_lev(self,
                      nrep,  #input[CMD_PAUSE_BITS-1:0]nrep;
                      verbose=0):
        """
        Setup write levelling sequence at parameter defined address in the sequencer memory
        <nrep>  number of times write levelling burst is repeated
        <verbose> print data being written (default: False)
        """
        dqs_low_rpt = 8
        nrep_minus_1 = nrep - 1;
        mr1_norm = self.func_ddr3_mr1(
            0, # 1'h0,     #       qoff; # output enable: 0 - DQ, DQS operate in normal mode, 1 - DQ, DQS are disabled
            0, # 1'h0,     #       tdqs; # termination data strobe (for x8 devices) 0 - disabled, 1 - enabled
            2, # 3'h2,     # [2:0] rtt;  # on-die termination resistance: #  3'b010 - RZQ/2 (120 Ohm)
            0, # 1'h0,     #       wlev; # write leveling
            0, # 2'h0,     #       ods;  # output drive strength: #  2'b00 - RZQ/6 - 40 Ohm
            0, # 2'h0,     # [1:0] al;   # additive latency: 2'b00 - disabled (AL=0)
            0) # 1'b0);    #       dll;  # 0 - DLL enabled (normal), 1 - DLL disabled
        mr1_wlev = self.func_ddr3_mr1(
            0, # 1'h0,     #       qoff; # output enable: 0 - DQ, DQS operate in normal mode, 1 - DQ, DQS are disabled
            0, # 1'h0,     #       tdqs; # termination data strobe (for x8 devices) 0 - disabled, 1 - enabled
            2, # 3'h2,     # [2:0] rtt;  # on-die termination resistance: #  3'b010 - RZQ/2 (120 Ohm)
            1, # 1'h1,     #       wlev; # write leveling
            0, # 2'h0,     #       ods;  # output drive strength: #  2'b00 - RZQ/6 - 40 Ohm
            0, # 2'h0,     # [1:0] al;   # additive latency: 2'b00 - disabled (AL=0)
            0) # 1'b0);    #       dll;  # 0 - DLL enabled (normal), 1 - DLL disabled
        cmd_addr = vrlg.MCONTR_CMD_WR_ADDR + vrlg.WRITELEV_OFFSET
# Enter write leveling mode
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr1_wlev,(14,0)), bits(mr1_wlev,(17,15)), 7,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 13,       0,          0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0) # tWLDQSEN=25tCK
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# enable DQS output, keep it low (15 more tCK for the total of 40 tCK
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(dqs_low_rpt,0,         0,                         1,  0,  0,  0,    1,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Toggle DQS as needed for write leveling, write to buffer
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(nrep_minus_1,0,        0,                         1,  0,  0,  0,    1,    1,    1,  1,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# continue toggling (5 times), but disable writing to buffer (used same wbuf latency as for read) 
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 4,        0,          0,                         1,  0,  0,  0,    1,    1,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # Keep DCI (but not ODT) active  ODT should be off befor MRS
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 2,        0,          0,                         0,  0,  0,  0,    0,    0,    1,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # exit write leveling mode, ODT off, DCI off
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr1_norm,(14,0)),bits(mr1_norm,(17,15)),  7,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 5,        0,         0,                          0,  0,  0,  0,    0,    0,    0,  0,   0,        0) # tMOD
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # Finalize. See if DONE can be combined with B_RST, if not - insert earlier
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,       1,           0,                        0,  0,  0,  0,    0,    0,    0,  0,   0,        1) # can DONE be combined with B_RST?
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1

    def set_refresh(self, #
                t_rfc,   # input[9:0]t_rfc; # =50 for tCK=2.5ns
                t_refi, # input[7:0]t_refi; # 48/97 for normal, 8 - for simulation
                en_refresh=0,
                verbose=0):
        """
        Setup refresh sequence at parameter defined address in the sequencer memory
        <t_rfc>       tRFC =50 for tCK=2.5ns
        <t_refi>      tREFI 48/97 for hardware, 16 - for simulation
        <en_refresh>  enable refresh immediately 
        <verbose> print data being written (default: False)
        """
        print("SET REFRESH: tRFC=%d, tREFI=%d"%(t_rfc,t_refi))
        cmd_addr = vrlg.MCONTR_CMD_WR_ADDR + vrlg.REFRESH_OFFSET
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(    0,                   0,                    6,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # =50 tREFI=260 ns before next ACTIVATE or REFRESH, @2.5ns clock, @5ns cycle
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( t_rfc,     0,          0,                        0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
# Ready for normal operation
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,       1,           0,                        0,  0,  0,  0,    0,    0,    0,  0,   0,        0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
#            write_contol_register(DLY_SET,0);
        self.x393_axi_tasks.write_contol_register(vrlg.MCONTR_TOP_16BIT_ADDR + vrlg.MCONTR_TOP_16BIT_REFRESH_ADDRESS, vrlg.REFRESH_OFFSET)
        self.x393_axi_tasks.write_contol_register(vrlg.MCONTR_TOP_16BIT_ADDR + vrlg.MCONTR_TOP_16BIT_REFRESH_PERIOD, t_refi)
        # enable refresh - should it be done here?
        if en_refresh:
            self.x393_axi_tasks.write_contol_register(vrlg.MCONTR_PHY_0BIT_ADDR +  vrlg.MCONTR_TOP_0BIT_REFRESH_EN + 1, 0)


    def set_mrs(self,       # will also calibrate ZQ
                reset_dll, # input reset_dll;
                verbose=0):
        """
        Setup sequence (at paramter-defined adderss) to write MR0, MR1, MR2 and MR3 mode registers of DDR3 memory
        <reset_dll>    reset memory DLL when running this sequence
        <verbose> print data being written (default: False)
        """
        mr0 = self.func_ddr3_mr0(
            0,         # 1'h0,      #       pd; # precharge power down 0 - dll off (slow exit), 1 - dll on (fast exit)
            2,         # 3'h2,      # [2:0] wr; # write recovery (encode ceil(tWR/tCK)) # 3'b010:  6
            reset_dll, # reset_dll, #       dll_rst; # 1 - dll reset (self clearing bit)
            4,         # 4'h4,      # [3:0] cl; # CAS latency: # 0100:  6 (time 15ns)
            0,         # 1'h0,      #       bt; # read burst type: 0 sequential (nibble), 1 - interleave
            0)         # 2'h0);       # [1:0] bl; # burst length: # 2'b00 - fixed BL8

        mr1 = self.func_ddr3_mr1(
            0,         # 1'h0,     #       qoff; # output enable: 0 - DQ, DQS operate in normal mode, 1 - DQ, DQS are disabled
            0,         # 1'h0,     #       tdqs; # termination data strobe (for x8 devices) 0 - disabled, 1 - enabled
            2,         # 3'h2,     # [2:0] rtt;  # on-die termination resistance: #  3'b010 - RZQ/2 (120 Ohm)
            0,         # 1'h0,     #       wlev; # write leveling
            0,         # 2'h0,     #       ods;  # output drive strength: #  2'b00 - RZQ/6 - 40 Ohm
            0,         # 2'h0,     # [1:0] al;   # additive latency: 2'b00 - disabled (AL=0)
            0)         # 1'b0);    #       dll;  # 0 - DLL enabled (normal), 1 - DLL disabled

        mr2 = self.func_ddr3_mr2(
            0,         # 2'h0,     # [1:0] rtt_wr; # Dynamic ODT : #  2'b00 - disabled, 2'b01 - RZQ/4 = 60 Ohm, 2'b10 - RZQ/2 = 120 Ohm
            0,         # 1'h0,     #       srt;    # Self-refresh temperature 0 - normal (0-85C), 1 - extended (<=95C)
            0,         # 1'h0,     #       asr;    # Auto self-refresh 0 - disabled (manual), 1 - enabled (auto)
            0)         # 3'h0);    # [2:0] cwl;    # CAS write latency:3'b000  5CK (tCK >= 2.5ns), 3'b001  6CK (1.875ns <= tCK < 2.5ns)

        mr3 = self.func_ddr3_mr3(
            0,         # 1'h0,     #       mpr;    # MPR mode: 0 - normal, 1 - dataflow from MPR
            0)         # 2'h0);    # [1:0] mpr_rf; # MPR read function: 2'b00: predefined pattern 0101...
        cmd_addr = vrlg.MCONTR_CMD_WR_ADDR + vrlg.INITIALIZE_OFFSET;
        if self.DEBUG_MODE > 1:
            print("mr0=0x%05x"%mr0);
            print("mr1=0x%05x"%mr1);
            print("mr2=0x%05x"%mr2);
            print("mr3=0x%05x"%mr3);
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr2,(14,0)),     bits(mr2,(17,15)),       7,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  1,       0,           0,                        0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr3,(14,0)),     bits(mr3,(17,15)),       7,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  0,      0,           0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr1,(14,0)),     bits(mr1,(17,15)),       7,  0,  0,  1,  0,    0,    0,    0,  0,   0,   0,   0) # SEL==1 - just testing?
        
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  2,       0,          0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd(bits(mr0,(14,0)),     bits(mr0,(17,15)),       7,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0)
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip(  5,       0,          0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # encode ZQCL:
        #                           addr                 bank                   RCW ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD NOP, B_RST
        data=self.func_encode_cmd( 0x400,                 0,                     1,  0,  0,  0,  0,    0,    0,    0,  0,   0,   0,   0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # 512 clock cycles after ZQCL
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 256,      0,          0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1
        # sequence done bit, skip length is ignored
        #                          skip      done        bank                       ODT CKE SEL DQEN DQSEN DQSTGL DCI B_WR B_RD      B_RST
        data=self.func_encode_skip( 10,       1,          0,                         0,  0,  0,  0,    0,    0,    0,  0,   0,        0);
        self.x393_mem.axi_write_single_w(cmd_addr, data, verbose)
        cmd_addr += 1

    def read_pattern(self,
                     num,
                     show_rslt,
                     wait_complete=1): # Wait for operation to complete
        """
        Read pattern 
        <num>           number of 32-bit words to read
        <show_rslt>     print read data
        <wait_complete> wait read pattern operation to complete (0 - may initiate multiple PS PIO operations)
        returns list of the read data
        """

        self.schedule_ps_pio ( # schedule software-control memory operation (may need to check FIFO status first)
                        vrlg.READ_PATTERN_OFFSET,   # input [9:0] seq_addr; # sequence start address
                        2,                          # input [1:0] page;     # buffer page number
                        0,                          # input       urgent;   # high priority request (only for competion with other channels, will not pass in this FIFO)
                        0,                          # input       chn;      # channel buffer to use: 0 - memory read, 1 - memory write
                        wait_complete) # `PS_PIO_WAIT_COMPLETE ) #  wait_complete; # Do not request a newe transaction from the scheduler until previous memory transaction is finished
        self.wait_ps_pio_done(vrlg.DEFAULT_STATUS_MODE,1) # wait previous memory transaction finished before changing delays (effective immediately)
        return self.x393_mcntrl_buffers.read_block_buf_chn (0, 2, num, show_rslt )    # chn=0, page=2, number of 32-bit words=num, show_rslt

    def read_block(self,
                     num,
                     show_rslt,
                     wait_complete=1): # Wait for operation to complete
        """
        Read block in PS PIO mode 
        <num>           number of 32-bit words to read
        <show_rslt>     print read data
        <wait_complete> wait read pattern operation to complete (0 - may initiate multiple PS PIO operations)
        returns list of the read data
        """
    
        self.schedule_ps_pio ( # schedule software-control memory operation (may need to check FIFO status first)
                        vrlg.READ_BLOCK_OFFSET,   # input [9:0] seq_addr; # sequence start address
                        3,                     # input [1:0] page;     # buffer page number
                        0,                     # input       urgent;   # high priority request (only for competion with other channels, will not pass in this FIFO)
                        0,                     # input       chn;      # channel buffer to use: 0 - memory read, 1 - memory write
                        wait_complete)         #  wait_complete; # Do not request a newe transaction from the scheduler until previous memory transaction is finished
        self.wait_ps_pio_done(vrlg.DEFAULT_STATUS_MODE,1); # wait previous memory transaction finished before changing delays (effective immediately)
        return self.x393_mcntrl_buffers.read_block_buf_chn (0, 3, num, show_rslt ) # chn=0, page=3, number of 32-bit words=num, show_rslt

    def write_block(self,
                     wait_complete): # Wait for operation to complete
        """
        Write block in PS PIO mode 
        <wait_complete> wait write block operation to complete (0 - may initiate multiple PS PIO operations)
        """
#    write_block_buf_chn; # fill block memory - already set in set_up task
        self.schedule_ps_pio ( # schedule software-control memory operation (may need to check FIFO status first)
                        vrlg.WRITE_BLOCK_OFFSET,    # input [9:0] seq_addr; # sequence start address
                        0,                     # input [1:0] page;     # buffer page number
                        0,                     # input       urgent;   # high priority request (only for competion with other channels, will not pass in this FIFO)
                        1,                     # input       chn;      # channel buffer to use: 0 - memory read, 1 - memory write
                        wait_complete)         # `PS_PIO_WAIT_COMPLETE )#  wait_complete; # Do not request a newer transaction from the scheduler until previous memory transaction is finished
# temporary - for debugging:
#        self.wait_ps_pio_done(vrlg.DEFAULT_STATUS_MODE,1) # wait previous memory transaction finished before changing delays (effective immediately)
