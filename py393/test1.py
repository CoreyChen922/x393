#!/usr/bin/env python
# encoding: utf-8
'''
# Copyright (C) 2015, Elphel.inc.
# test for import_verilog_parameters.py
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

import sys
import os

from argparse import ArgumentParser
#import argparse
from argparse import RawDescriptionHelpFormatter

from import_verilog_parameters import ImportVerilogParameters
from import_verilog_parameters import VerilogParameters
__all__ = []
__version__ = 0.1
__date__ = '2015-03-01'
__updated__ = '2015-03-01'

DEBUG = 1
TESTRUN = 0
PROFILE = 0

class CLIError(Exception):
    #Generic exception to raise and log different fatal errors.
    def __init__(self, msg):
        super(CLIError).__init__(type(self))
        self.msg = "E: %s" % msg
    def __str__(self):
        return self.msg
    def __unicode__(self):
        return self.msg


def main(argv=None): # IGNORE:C0111
    '''Command line options.'''

    if argv is None:
        argv = sys.argv
    else:
        sys.argv.extend(argv)
        
    program_name = os.path.basename(sys.argv[0])
    program_version = "v%s" % __version__
    program_build_date = str(__updated__)
    program_version_message = '%%(prog)s %s (%s)' % (program_version, program_build_date)
    program_shortdesc = __import__('__main__').__doc__.split("\n")[1]
    program_license = '''%s

  Created by %s on %s.
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

USAGE
''' % (program_shortdesc, __author__,str(__date__))
    preDefines={}
    preParameters={}
    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_license, formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument("-v", "--verbose", dest="verbose", action="count", help="set verbosity level [default: %(default)s]")
        parser.add_argument('-V', '--version', action='version', version=program_version_message)
        parser.add_argument(                   dest="paths", help="Verilog include files with parameter definitions [default: %(default)s]", metavar="path", nargs='*')
        parser.add_argument("-d", "--define",  dest="defines", action="append", help="Define macro(s)" )
        parser.add_argument("-p", "--parameter",  dest="parameters", action="append", help="Define parameter(s) as name=value" )
        
        # Process arguments
        args = parser.parse_args()
        paths = args.paths
        verbose = args.verbose
        if args.defines:
            for predef in args.defines:
                kv=predef.split("=")
                if len(kv)<2:
                    kv.append("")
                preDefines[kv[0].strip("`")]=kv[1]    
        if verbose > 0:
#            print("Verbose mode on "+hex(verbose))
            args.parameters.append('VERBOSE=%d'%verbose) # add as verilog parameter
        if args.parameters:
            for prePars in args.parameters:
                kv=prePars.split("=")
                if len(kv)>1:
                    preParameters[kv[0]]=(kv[1],"RAW",kv[1]) # todo - need to go through the parser
                    
    except KeyboardInterrupt:
        ### handle keyboard interrupt ###
        return 0
    except Exception, e:
        if DEBUG or TESTRUN:
            raise(e)
        indent = len(program_name) * " "
        sys.stderr.write(program_name + ": " + repr(e) + "\n")
        sys.stderr.write(indent + "  for help use --help")
        return 2
# Take out from the try/except for debugging
    ivp= ImportVerilogParameters(preParameters,preDefines)   
    for path in paths:
        ### do something with inpath ###
        ivp.readParameterPortList(path)
    parameters=ivp.getParameters()
    vpars=VerilogParameters(parameters)
    if verbose > 3:
        defines= ivp.getDefines()
        print ("======= Extracted defines =======")
        for macro in defines:
            print ("`"+macro+": "+defines[macro])        
        print ("======= Parameters =======")
        for par in parameters:
            try:
                print (par+" = "+hex(parameters[par][0])+" (type = "+parameters[par][1]+" raw = "+parameters[par][2]+")")        
            except:
                print (par+" = "+str(parameters[par][0])+" (type = "+parameters[par][1]+" raw = "+parameters[par][2]+")")
        print("vpars.VERBOSE="+str(vpars.VERBOSE))
        print("vpars.VERBOSE__TYPE="+str(vpars.VERBOSE__TYPE))
        print("vpars.VERBOSE__RAW="+str(vpars.VERBOSE__RAW))
    
    print (VerilogParameters.__dict__)
    vpars1=VerilogParameters()
    print("vpars1.VERBOSE="+str(vpars1.VERBOSE))
    print("vpars1.VERBOSE__TYPE="+str(vpars1.VERBOSE__TYPE))
    print("vpars1.VERBOSE__RAW="+str(vpars1.VERBOSE__RAW))
    
       
    return 0

if __name__ == "__main__":
    if DEBUG:
#        sys.argv.append("-h")
        sys.argv.append("-v")
    if TESTRUN:
        import doctest
        doctest.testmod()
    if PROFILE:
        import cProfile
        import pstats
        profile_filename = 'test1_profile.txt'
        cProfile.run('main()', profile_filename)
        statsfile = open("profile_stats.txt", "wb")
        p = pstats.Stats(profile_filename, stream=statsfile)
        stats = p.strip_dirs().sort_stats('cumulative')
        stats.print_stats()
        statsfile.close()
        sys.exit(0)
    sys.exit(main())