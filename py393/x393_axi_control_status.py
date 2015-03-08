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
from import_verilog_parameters import VerilogParameters
from x393_mem import X393Mem
#from verilog_utils import hx,concat, bits 
from verilog_utils import hx
        
class X393AxiControlStatus(object):
    DRY_MODE= True # True
    DEBUG_MODE=1
#    vpars=None
    x393_mem=None
    enabled_channels=0 # currently enable channels
#    verbose=1
    def __init__(self, debug_mode=1,dry_mode=True):
        self.DEBUG_MODE=debug_mode
        self.DRY_MODE=dry_mode
#        self.vpars=VerilogParameters()
        self.x393_mem=X393Mem(debug_mode,dry_mode)
#        print ("+++++++++++++++ self.__dict__ ++++++++++++++++++++++++++")
#        print (self.__dict__)
#        print ("+++++++++++++++ VerilogParameters.__dict__ ++++++++++++++++++++++++++")
#        print (VerilogParameters.__dict__)
#        self.__dict__.update(VerilogParameters.__dict__) # Add verilog parameters to the class namespace
        self.__dict__.update(VerilogParameters.__dict__["_VerilogParameters__shared_state"]) # Add verilog parameters to the class namespace
#        try:
#            verbose=self.verbose
#        except:
#            pass
#        print ("+++++++++++++++ self.__dict__ ++++++++++++++++++++++++++")
#        print (self.__dict__)
        '''
        Maybe import parameters into the module, not class namespace to use directly, w/o self. ?
#        __dict__.update(VerilogParameters.__dict__) # Add verilog parameters to the class namespace
        '''
        
    def write_contol_register(self, reg_addr, data):
        self.x393_mem.axi_write_single_w(self.CONTROL_ADDR+reg_addr, data)
    def read_and_wait_status(self, address):
        return self.x393_mem.axi_read_addr_w(self.STATUS_ADDR + address )
    
    def wait_status_condition(self,
                              status_address,         # input [STATUS_DEPTH-1:0] status_address;
                              status_control_address, # input [29:0] status_control_address;
                              status_mode,            # input  [1:0] status_mode;
                              pattern,                # input [25:0] pattern;        // bits as in read registers
                              mask,                   # input [25:0] mask;           // which bits to compare
                              invert_match,           # input        invert_match;   // 0 - wait until match to pattern (all bits), 1 - wait until no match (any of bits differ)
                              wait_seq):              # input        wait_seq; // Wait for the correct sequence number, False assume correct
        match=False
        while not match:
            data=self.read_and_wait_status(status_address)
            if wait_seq:
                seq_num = ((data >> self.STATUS_SEQ_SHFT) ^ 0x20) & 0x30
                data=self.read_and_wait_status(status_address)
                while (((data >> self.STATUS_SEQ_SHFT) ^ seq_num) & 0x30) !=0:
                    data=self.read_and_wait_status(status_address)
                    if self.DRY_MODE: break
            match = (((data ^ pattern) & mask & 0x3ffffff)==0)
            if invert_match:
                match = not match
            if self.DRY_MODE: break

    def read_all_status(self):
#        print (self.__dict__)
#        for name in self.__dict__:
#            print (name+": "+str(name=='MCONTR_PHY_STATUS_REG_ADDR'))
#        print (self.__dict__['MCONTR_PHY_STATUS_REG_ADDR'])
        print ("MCONTR_PHY_STATUS_REG_ADDR:          %s"%(hx(self.read_and_wait_status(self.MCONTR_PHY_STATUS_REG_ADDR))))
        print ("MCONTR_TOP_STATUS_REG_ADDR:          %s"%(hx(self.read_and_wait_status(self.MCONTR_TOP_STATUS_REG_ADDR))))
        print ("MCNTRL_PS_STATUS_REG_ADDR:           %s"%(hx(self.read_and_wait_status(self.MCNTRL_PS_STATUS_REG_ADDR))))
        print ("MCNTRL_SCANLINE_STATUS_REG_CHN1_ADDR:%s"%(hx(self.read_and_wait_status(self.MCNTRL_SCANLINE_STATUS_REG_CHN1_ADDR))))
        print ("MCNTRL_SCANLINE_STATUS_REG_CHN3_ADDR:%s"%(hx(self.read_and_wait_status(self.MCNTRL_SCANLINE_STATUS_REG_CHN3_ADDR))))
        print ("MCNTRL_TILED_STATUS_REG_CHN2_ADDR:   %s"%(hx(self.read_and_wait_status(self.MCNTRL_TILED_STATUS_REG_CHN2_ADDR))))
        print ("MCNTRL_TILED_STATUS_REG_CHN4_ADDR:   %s"%(hx(self.read_and_wait_status(self.MCNTRL_TILED_STATUS_REG_CHN4_ADDR))))
        print ("MCNTRL_TEST01_STATUS_REG_CHN1_ADDR:  %s"%(hx(self.read_and_wait_status(self.MCNTRL_TEST01_STATUS_REG_CHN1_ADDR))))
        print ("MCNTRL_TEST01_STATUS_REG_CHN2_ADDR:  %s"%(hx(self.read_and_wait_status(self.MCNTRL_TEST01_STATUS_REG_CHN2_ADDR))))
        print ("MCNTRL_TEST01_STATUS_REG_CHN3_ADDR:  %s"%(hx(self.read_and_wait_status(self.MCNTRL_TEST01_STATUS_REG_CHN3_ADDR))))
        print ("MCNTRL_TEST01_STATUS_REG_CHN4_ADDR:  %s"%(hx(self.read_and_wait_status(self.MCNTRL_TEST01_STATUS_REG_CHN4_ADDR))))

    def program_status(self,
                       base_addr,   # input [29:0] base_addr;
                       reg_addr,    # input  [7:0] reg_addr;
                       mode,        # input  [1:0] mode;
                       seq_number): # input  [5:0] seq_number;
        '''
 // mode bits:
 // 0 disable status generation,
 // 1 single status request,
 // 2 - auto status, keep specified seq number,
 // 3 - auto, inc sequence number
         '''
        self.write_contol_register(base_addr + reg_addr, ((mode & 3)<< 6) | (seq_number * 0x3f))


    def program_status_all( self,
                            mode,     # input [1:0] mode;
                            seq_num): # input [5:0] seq_num;
        self.program_status (self.MCONTR_PHY_16BIT_ADDR,     self.MCONTR_PHY_STATUS_CNTRL,        mode,seq_num)# //MCONTR_PHY_STATUS_REG_ADDR=          'h0,
        self.program_status (self.MCONTR_TOP_16BIT_ADDR,     self.MCONTR_TOP_16BIT_STATUS_CNTRL,  mode,seq_num)# //MCONTR_TOP_STATUS_REG_ADDR=          'h1,
        self.program_status (self.MCNTRL_PS_ADDR,            self.MCNTRL_PS_STATUS_CNTRL,         mode,seq_num)# //MCNTRL_PS_STATUS_REG_ADDR=           'h2,
        self.program_status (self.MCNTRL_SCANLINE_CHN1_ADDR, self.MCNTRL_SCANLINE_STATUS_CNTRL,   mode,seq_num)#; //MCNTRL_SCANLINE_STATUS_REG_CHN2_ADDR='h4,
        self.program_status (self.MCNTRL_SCANLINE_CHN3_ADDR, self.MCNTRL_SCANLINE_STATUS_CNTRL,   mode,seq_num)# //MCNTRL_SCANLINE_STATUS_REG_CHN3_ADDR='h5,
        self.program_status (self.MCNTRL_TILED_CHN2_ADDR,    self.MCNTRL_TILED_STATUS_CNTRL,      mode,seq_num)# //MCNTRL_TILED_STATUS_REG_CHN4_ADDR=   'h6,
        self.program_status (self.MCNTRL_TILED_CHN4_ADDR,    self.MCNTRL_TILED_STATUS_CNTRL,      mode,seq_num)#; //MCNTRL_TILED_STATUS_REG_CHN4_ADDR=   'h6,
        self.program_status (self.MCNTRL_TEST01_ADDR,        self.MCNTRL_TEST01_CHN1_STATUS_CNTRL,mode,seq_num)#; //MCNTRL_TEST01_STATUS_REG_CHN2_ADDR=  'h3c,
        self.program_status (self.MCNTRL_TEST01_ADDR,        self.MCNTRL_TEST01_CHN2_STATUS_CNTRL,mode,seq_num)#; //MCNTRL_TEST01_STATUS_REG_CHN2_ADDR=  'h3c,
        self.program_status (self.MCNTRL_TEST01_ADDR,        self.MCNTRL_TEST01_CHN3_STATUS_CNTRL,mode,seq_num)#; //MCNTRL_TEST01_STATUS_REG_CHN3_ADDR=  'h3d,
        self.program_status (self.MCNTRL_TEST01_ADDR,        self.MCNTRL_TEST01_CHN4_STATUS_CNTRL,mode,seq_num)#; //MCNTRL_TEST01_STATUS_REG_CHN4_ADDR=  'h3e,
        
    def enable_cmda(self,
                    en): # input en;
        self.write_contol_register(self.MCONTR_PHY_0BIT_ADDR +  self.MCONTR_PHY_0BIT_CMDA_EN + en, 0);
            
    def enable_cke(self,
                    en): # input en;
        self.write_contol_register(self.MCONTR_PHY_0BIT_ADDR +  self.MCONTR_PHY_0BIT_CKE_EN + en, 0);

    def activate_sdrst(self,
                    en): # input en;
        self.write_contol_register(self.MCONTR_PHY_0BIT_ADDR +  self.MCONTR_PHY_0BIT_SDRST_ACT + en, 0);

    def enable_refresh(self,
                    en): # input en;
        self.write_contol_register(self.MCONTR_TOP_0BIT_ADDR +  self.MCONTR_TOP_0BIT_REFRESH_EN + en, 0);
        
    def enable_memcntrl(self,
                    en): # input en;
        self.write_contol_register(self.MCONTR_TOP_0BIT_ADDR +  self.MCONTR_TOP_0BIT_MCONTR_EN + en, 0);
        
    def enable_memcntrl_channels(self,
                                 chnen): # input [15:0] chnen; // bit-per-channel, 1 - enable;
        self.enabled_channels = chnen; # currently enabled memory channels
        self.write_contol_register(self.MCONTR_TOP_16BIT_ADDR +  self.MCONTR_TOP_16BIT_CHN_EN, self.enabled_channels & 0xffff) # {16'b0,chnen});

    def enable_memcntrl_en_dis(self,
                               chn, # input [3:0] chn;
                               en):# input       en;
        if en:
            self.enabled_channels = self.enabled_channels | (1<<chn);
        else:
            self.enabled_channels = self.enabled_channels & ~(1<<chn);
        self.write_contol_register(self.MCONTR_TOP_16BIT_ADDR + self. MCONTR_TOP_16BIT_CHN_EN, self.enabled_channels & 0xffff) #  {16'b0,ENABLED_CHANNELS});

    def configure_channel_priority(self,
                                   chn, # input [ 3:0] chn;
                                   priority): #input [15:0] priority; // (higher is more important)
        self.write_contol_register(self.MCONTR_ARBIT_ADDR + chn, priority  & 0xffff)# {16'b0,priority});

