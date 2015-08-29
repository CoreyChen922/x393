from __future__ import division
from __future__ import print_function

'''
# Copyright (C) 2015, Elphel.inc.
# Class to control JPEG/JP4 compressor  
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
# along with this program.  If not, see <http:#www.gnu.org/licenses/>.

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
#import pickle
from x393_mem                import X393Mem
import x393_axi_control_status

import x393_utils

#import time
import vrlg
class X393Cmprs(object):
    DRY_MODE= True # True
    DEBUG_MODE=1
    x393_mem=None
    x393_axi_tasks=None #x393X393AxiControlStatus
    x393_utils=None
    verbose=1
    def __init__(self, debug_mode=1,dry_mode=True, saveFileName=None):
        self.DEBUG_MODE=  debug_mode
        self.DRY_MODE=    dry_mode
        self.x393_mem=            X393Mem(debug_mode,dry_mode)
        self.x393_axi_tasks=      x393_axi_control_status.X393AxiControlStatus(debug_mode,dry_mode)
        self.x393_utils=          x393_utils.X393Utils(debug_mode,dry_mode, saveFileName) # should not overwrite save file path
        try:
            self.verbose=vrlg.VERBOSE
        except:
            pass
    
    def program_status_compressor(self,
                                  cmprs_chn,
                                  mode,     # input [1:0] mode;
                                  seq_num): # input [5:0] seq_num;
        """
        Set status generation mode for selected compressor channel
        @param cmprs_chn - number of the compressor channel (0..3)
        @param mode -       status generation mode:
                                  0: disable status generation,
                                  1: single status request,
                                  2: auto status, keep specified seq number,
                                  4: auto, inc sequence number 
        @param seq_number - 6-bit sequence number of the status message to be sent
        """

        self.x393_axi_tasks.program_status (
                             vrlg.CMPRS_GROUP_ADDR  + cmprs_chn * vrlg.CMPRS_BASE_INC,
                             vrlg.CMPRS_STATUS_CNTRL,
                             mode,
                             seq_num)# //MCONTR_PHY_STATUS_REG_ADDR=          'h0,
    def func_compressor_format (self,
                                num_macro_cols_m1,
                                num_macro_rows_m1,
                                left_margin):
        """
        @param num_macro_cols_m1 - number of macroblock colums minus 1
        @param num_macro_rows_m1 - number of macroblock rows minus 1
        @param left_margin - left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
        @return combined compressor format data word
        """
        data = 0;
        data |=(num_macro_cols_m1 & ((1 << vrlg.CMPRS_FRMT_MBCM1_BITS) - 1))  << vrlg.CMPRS_FRMT_MBCM1
        data |=(num_macro_rows_m1 & ((1 << vrlg.CMPRS_FRMT_MBRM1_BITS) - 1))  << vrlg.CMPRS_FRMT_MBRM1
        data |=(left_margin &       ((1 << vrlg.CMPRS_FRMT_LMARG_BITS) - 1))  << vrlg.CMPRS_FRMT_LMARG
        return data
        
    def func_compressor_color_saturation (self,
                                colorsat_blue,
                                colorsat_red):
        """
        @param colorsat_blue - color saturation for blue (10 bits), 0x90 for 100%
        @param colorsat_red -  color saturation for red (10 bits), 0xb6 for 100%
        @return combined compressor format data word
        """
        data = 0;
        data |=(colorsat_blue & ((1 << vrlg.CMPRS_CSAT_CB_BITS) - 1))  << vrlg.CMPRS_CSAT_CB
        data |=(colorsat_red &  ((1 << vrlg.CMPRS_CSAT_CR_BITS) - 1))  << vrlg.CMPRS_CSAT_CR
        return data
    def func_compressor_control (self,
                                 run_mode =    None,
                                 qbank =       None,
                                 dc_sub =      None,
                                 cmode =       None,
                                 multi_frame = None,
                                 bayer =       None,
                                 focus_mode =  None):
        """
        Combine compressor control parameters into a single word. None value preserves old setting for the parameter
        @param run_mode -    0 - reset, 2 - run single from memory, 3 - run repetitive
        @param qbank -       quantization table page (0..15)
        @param dc_sub -      True - subtract DC before running DCT, False - no subtraction, convert as is,
        @param cmode -       color mode:
                                CMPRS_CBIT_CMODE_JPEG18 =          0 - color 4:2:0
                                CMPRS_CBIT_CMODE_MONO6 =           1 - mono 4:2:0 (6 blocks)
                                CMPRS_CBIT_CMODE_JP46 =            2 - jp4, 6 blocks, original
                                CMPRS_CBIT_CMODE_JP46DC =          3 - jp4, 6 blocks, dc -improved
                                CMPRS_CBIT_CMODE_JPEG20 =          4 - mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
                                CMPRS_CBIT_CMODE_JP4 =             5 - jp4,  4 blocks, dc-improved
                                CMPRS_CBIT_CMODE_JP4DC =           6 - jp4,  4 blocks, dc-improved
                                CMPRS_CBIT_CMODE_JP4DIFF =         7 - jp4,  4 blocks, differential
                                CMPRS_CBIT_CMODE_JP4DIFFHDR =      8 - jp4,  4 blocks, differential, hdr
                                CMPRS_CBIT_CMODE_JP4DIFFDIV2 =     9 - jp4,  4 blocks, differential, divide by 2
                                CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 10 - jp4,  4 blocks, differential, hdr,divide by 2
                                CMPRS_CBIT_CMODE_MONO1 =          11 -  mono JPEG (not yet implemented)
                                CMPRS_CBIT_CMODE_MONO4 =          14 -  mono 4 blocks
        @param multi_frame -  False - single-frame buffer, True - multi-frame video memory buffer,
        @param bayer -        Bayer shift (0..3)
        @param focus_mode -   focus mode - how to combine image with "focus quality" in the result image 
        @return               combined data word
        """
        data = 0;
        if not run_mode is None:
            data |= (1 << vrlg.CMPRS_CBIT_RUN_BITS)
            data |= (run_mode & ((1 << vrlg.CMPRS_CBIT_RUN_BITS) - 1)) << (vrlg.CMPRS_CBIT_RUN - vrlg.CMPRS_CBIT_RUN_BITS)
                     
        if not qbank is None:
            data |= (1 << vrlg.CMPRS_CBIT_QBANK_BITS)
            data |= (qbank & ((1 << vrlg.CMPRS_CBIT_QBANK_BITS) - 1)) << (vrlg.CMPRS_CBIT_QBANK - vrlg.CMPRS_CBIT_QBANK_BITS)

        if not dc_sub is None:
            data |= (1 << vrlg.CMPRS_CBIT_DCSUB_BITS)
            data |= (dc_sub & ((1 << vrlg.CMPRS_CBIT_DCSUB_BITS) - 1)) << (vrlg.CMPRS_CBIT_DCSUB - vrlg.CMPRS_CBIT_DCSUB_BITS)

        if not cmode is None:
            data |= (1 << vrlg.CMPRS_CBIT_CMODE_BITS)
            data |= (cmode & ((1 << vrlg.CMPRS_CBIT_CMODE_BITS) - 1)) << (vrlg.CMPRS_CBIT_CMODE - vrlg.CMPRS_CBIT_CMODE_BITS)
                     
        if not multi_frame is None:
            data |= (1 << vrlg.CMPRS_CBIT_FRAMES_BITS)
            data |= (multi_frame & ((1 << vrlg.CMPRS_CBIT_FRAMES_BITS) - 1)) << (vrlg.CMPRS_CBIT_FRAMES - vrlg.CMPRS_CBIT_FRAMES_BITS)
                     
        if not bayer is None:
            data |= (1 << vrlg.CMPRS_CBIT_BAYER_BITS)
            data |= (bayer & ((1 << vrlg.CMPRS_CBIT_BAYER_BITS) - 1)) << (vrlg.CMPRS_CBIT_BAYER - vrlg.CMPRS_CBIT_BAYER_BITS)
                     
        if not focus_mode is None:
            data |= (1 << vrlg.CMPRS_CBIT_FOCUS_BITS)
            data |= (focus_mode & ((1 << vrlg.CMPRS_CBIT_FOCUS_BITS) - 1)) << (vrlg.CMPRS_CBIT_FOCUS - vrlg.CMPRS_CBIT_FOCUS_BITS)
        return data
    
    def compressor_format (self,
                           chn,
                           num_macro_cols_m1,
                           num_macro_rows_m1,
                           left_margin):
        """
        @param chn -               compressor channel number
        @param num_macro_cols_m1 - number of macroblock colums minus 1
        @param num_macro_rows_m1 - number of macroblock rows minus 1
        @param left_margin - left margin of the first pixel (0..31) for 32-pixel wide colums in memory access
        """
        data = self.func_compressor_format (num_macro_cols_m1 = num_macro_cols_m1,
                                            num_macro_rows_m1 = num_macro_rows_m1,
                                            left_margin =       left_margin)
        self.x393_axi_tasks.write_contol_register(vrlg.CMPRS_GROUP_ADDR +  chn * vrlg.CMPRS_BASE_INC + vrlg.CMPRS_FORMAT,
                                                  data)

    def compressor_color_saturation (self,
                                     chn,
                                     colorsat_blue,
                                     colorsat_red):
        """
        @param chn -           compressor channel number
        @param colorsat_blue - color saturation for blue (10 bits), 0x90 for 100%
        @param colorsat_red -  color saturation for red (10 bits), 0xb6 for 100%
        """
        data = self.func_compressor_color_saturation (colorsat_blue = colorsat_blue,
                                                      colorsat_red = colorsat_red)
        self.x393_axi_tasks.write_contol_register(vrlg.CMPRS_GROUP_ADDR +  chn * vrlg.CMPRS_BASE_INC + vrlg.CMPRS_COLOR_SATURATION,
                                                  data)

    def compressor_coring (self,
                           chn,
                           coring):
        """
        @param chn -    compressor channel number
        @param coring - coring value
        """
        data = coring & ((1 << vrlg.CMPRS_CORING_BITS) - 1)
        self.x393_axi_tasks.write_contol_register(vrlg.CMPRS_GROUP_ADDR +  chn * vrlg.CMPRS_BASE_INC + vrlg.CMPRS_CORING_MODE,
                                                  data)

    def compressor_control (self,
                            chn,
                            run_mode =    None,
                            qbank =       None,
                            dc_sub =      None,
                            cmode =       None,
                            multi_frame = None,
                            bayer =       None,
                            focus_mode =  None):
        """
        Combine compressor control parameters into a single word. None value preserves old setting for the parameter
        @param chn -           compressor channel number
        @param run_mode -    0 - reset, 2 - run single from memory, 3 - run repetitive
        @param qbank -       quantization table page (0..15)
        @param dc_sub -      True - subtract DC before running DCT, False - no subtraction, convert as is,
        @param cmode -       color mode:
                                CMPRS_CBIT_CMODE_JPEG18 =          0 - color 4:2:0
                                CMPRS_CBIT_CMODE_MONO6 =           1 - mono 4:2:0 (6 blocks)
                                CMPRS_CBIT_CMODE_JP46 =            2 - jp4, 6 blocks, original
                                CMPRS_CBIT_CMODE_JP46DC =          3 - jp4, 6 blocks, dc -improved
                                CMPRS_CBIT_CMODE_JPEG20 =          4 - mono, 4 blocks (but still not actual monochrome JPEG as the blocks are scanned in 2x2 macroblocks)
                                CMPRS_CBIT_CMODE_JP4 =             5 - jp4,  4 blocks, dc-improved
                                CMPRS_CBIT_CMODE_JP4DC =           6 - jp4,  4 blocks, dc-improved
                                CMPRS_CBIT_CMODE_JP4DIFF =         7 - jp4,  4 blocks, differential
                                CMPRS_CBIT_CMODE_JP4DIFFHDR =      8 - jp4,  4 blocks, differential, hdr
                                CMPRS_CBIT_CMODE_JP4DIFFDIV2 =     9 - jp4,  4 blocks, differential, divide by 2
                                CMPRS_CBIT_CMODE_JP4DIFFHDRDIV2 = 10 - jp4,  4 blocks, differential, hdr,divide by 2
                                CMPRS_CBIT_CMODE_MONO1 =          11 -  mono JPEG (not yet implemented)
                                CMPRS_CBIT_CMODE_MONO4 =          14 -  mono 4 blocks
        @param multi_frame -  False - single-frame buffer, True - multi-frame video memory buffer,
        @param bayer -        Bayer shift (0..3)
        @param focus_mode -   focus mode - how to combine image with "focus quality" in the result image 
        """
        data = self.func_compressor_control(
                            run_mode =    run_mode,
                            qbank =       qbank,
                            dc_sub =      dc_sub,
                            cmode =       cmode,
                            multi_frame = multi_frame,
                            bayer =       bayer,
                            focus_mode =  focus_mode)
        self.x393_axi_tasks.write_contol_register(vrlg.CMPRS_GROUP_ADDR +  chn * vrlg.CMPRS_BASE_INC + vrlg.CMPRS_CONTROL_REG,
                                                  data)

