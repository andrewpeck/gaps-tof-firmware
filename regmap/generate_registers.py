#!/usr/bin/python3
from __future__ import unicode_literals

__author__ = 'evka'

import json
import io
import xml.etree.ElementTree as xml
import textwrap as tw
import argparse
import sys
import rw_reg
import shutil
import tempfile
from insert_code import *

SUFFIX                        =  ''
ADDRESS_TABLE_TOP             =  ''
CONSTANTS_FILE                =  ''
DOC_FILE                      =  ''
PACKAGE_FILE                  =  ''
TOP_NODE_NAME                 =  ''
VHDL_REG_GENERATED_DISCLAIMER =  ''

USED_REGISTER_SPACE           =  {}

BASH_STATUS_SCRIPT_FILE     = './ctp7_bash_scripts/generated/ctp7_status.sh'
BASH_REG_READ_SCRIPT_FILE   = './ctp7_bash_scripts/generated/reg_read.sh'
UHAL_ADDRESS_TABLE_FILE_CTP7='./address_table/uhal_gem_amc_ctp7'
UHAL_ADDRESS_TABLE_FILE_GLIB='./address_table/uhal_gem_amc_glib'

VHDL_REG_CONSTANT_PREFIX = 'REG_'

VHDL_REG_SIGNAL_MARKER_START = '------ Register signals begin'
VHDL_REG_SIGNAL_MARKER_END   = '------ Register signals end'

VHDL_REG_SLAVE_MARKER_START = '--==== Registers begin'
VHDL_REG_SLAVE_MARKER_END   = '--==== Registers end'

AXI_IPB_BASE_ADDRESS = 0x64000000
GLIB_IPB_BASE_ADDRESS = 0x40000000

class Module:
    name = ''
    description = ''
    baseAddress = 0x0
    regAddressMsb = None
    regAddressLsb = None
    file = ''
    userClock = ''
    busClock = ''
    busReset = ''
    fw_cnt_reset_signal = None
    masterBus = ''
    slaveBus = ''
    isExternal = False # if this is true it means that firmware doesn't have to be modified, only bash scripts will be generated

    def __init__(self):
        self.regs    = []
        self.parents = []

    def addReg(self, reg):
        self.regs.append(reg)

    def addParent(self, parent):
        self.parents.append(parent)

    def isValid(self):
        if self.isExternal:
            return self.name is not None
        else:
            return self.name is not None and self.file is not None and self.userClock is not None and self.busClock is not None\
                   and self.busReset is not None and self.masterBus is not None and self.slaveBus is not None\
                   and self.regAddressMsb is not None and self.regAddressLsb is not None

    def toString(self):
        return str(self.name) + ' module: ' + str(self.description) + '\n'\
                         + '    Base address = ' + hex(self.baseAddress) + '\n'\
                         + '    Register address MSB = ' + hex(self.regAddressMsb) + '\n'\
                         + '    Register address LSB = ' + hex(self.regAddressLsb) + '\n'\
                         + '    File = ' + str(self.file) + '\n'\
                         + '    User clock = ' + str(self.userClock) + '\n'\
                         + '    Bus clock = ' + str(self.busClock) + '\n'\
                         + '    Bus reset = ' + str(self.busReset) + '\n'\
                         + '    Master_bus = ' + str(self.masterBus) + '\n'\
                         + '    Slave_bus = ' + str(self.slaveBus)

    def getVhdlName(self):
        return self.name.replace(TOP_NODE_NAME + '.', '').replace('.', '_')

class Register:

    name               = ''
    name_raw           = ''
    address            = 0x0
    description        = ''
    description_raw    = ''
    permission         = ''
    mask               = 0x0
    signal             = None
    write_pulse_signal = None
    write_done_signal  = None
    read_pulse_signal  = None
    read_ready_signal  = None

    genvars = {}
    gensize = {}
    genstep = {}

    # count signals
    fw_cnt_snap_signal    = '\'1\''
    fw_cnt_allow_rollover = 'false'
    fw_cnt_increment_step = '1'
    fw_cnt_reset_signal   = None
    fw_cnt_en_signal      = None
    fw_make_signal        = 'true'

    fw_rate_clk_frequency = 40079000 # clock frequency in Hz
    fw_rate_reset_signal  = None     # Reset input
    fw_rate_en_signal     = None     # Enable

    default = 0x0
    msb = -1
    lsb = -1

    def isValidReg(self, isExternal = False):
        if isExternal:
            return self.name is not None and self.address is not None and self.permission is not None\
                   and self.mask is not None
        else:
            return self.name is not None and self.address is not None and self.permission is not None\
                   and self.mask is not None \
                   and ((self.signal is not None and 'w' in self.permission) == (self.default is not None)) \
                   and (self.signal is not None or self.write_pulse_signal is not None or self.read_pulse_signal is not None)

    def toString(self):
        ret = 'Register ' + str(self.name) + ': ' + str(self.description) + '\n'\
              '    Address = ' + hex(self.address) + '\n'\
              '    Mask = ' + hexPadded32(self.mask) + '\n'\
              '    Permission = ' + str(self.permission) + '\n'\
              '    Default value = ' + hexPadded32(self.default) + '\n'\

        if self.signal is not None:
            ret += '    Signal = ' + str(self.signal) + '\n'
        if self.write_pulse_signal is not None:
            ret += '    Write pulse signal = ' + str(self.write_pulse_signal) + '\n'
        if self.write_done_signal is not None:
            ret += '    Write done signal = ' + str(self.write_done_signal) + '\n'
        if self.read_pulse_signal is not None:
            ret += '    Read pulse signal = ' + str(self.read_pulse_signal) + '\n'
        if self.read_ready_signal is not None:
            ret += '    Read ready signal = ' + str(self.read_ready_signal) + '\n'

        return ret

    def getVhdlName(self):
        return self.name.replace(TOP_NODE_NAME + '.', '').replace('.', '_')

def main(CONFIG):
    num_of_oh = 0
    parser = argparse.ArgumentParser()

    parser.add_argument('-s',
                        '--suffix',
                        dest='suffix',
                        help="Specify an optional suffix to copy the file onto")

    parser.add_argument('-n',
                        '--num_ohs',
                        dest='num_ohs',
                        help="Number of optohybrids to build for")

    parser.add_argument('board_type',
                        help="Choose board type (ctp7 or glib or oh)")

    args = parser.parse_args()

    board_type = args.board_type

    global ADDRESS_TABLE_TOP
    global CONSTANTS_FILE
    global DOC_FILE
    global PACKAGE_FILE
    global TOP_NODE_NAME
    global VHDL_REG_GENERATED_DISCLAIMER
    global SUFFIX

    if args.suffix is not None:
        SUFFIX = args.suffix;

    ADDRESS_TABLE_TOP             = CONFIG['ADDRESS_TABLE_TOP']
    CONSTANTS_FILE                = CONFIG['CONSTANTS_FILE']
    DOC_FILE                      = CONFIG['DOC_FILE']
    ORG_FILE                      = CONFIG['ORG_FILE']
    JSON_FILE                     = CONFIG['JSON_FILE']
    PACKAGE_FILE                  = CONFIG['PACKAGE_FILE']
    TOP_NODE_NAME                 = CONFIG['TOP_NODE_NAME']
    VHDL_REG_GENERATED_DISCLAIMER = CONFIG['VHDL_REG_GENERATED_DISCLAIMER']

    ADDRESS_TABLE_TOP = ADDRESS_TABLE_TOP.replace(".xml",SUFFIX+".xml")
    print('Hi, parsing this top address table file: ' + ADDRESS_TABLE_TOP)

    tree = xml.parse(ADDRESS_TABLE_TOP)
    root = tree.getroot()

    modules = []
    vars = {}

    findRegisters(root, '', 0x0, modules, None, vars, False, num_of_oh)

    print('Modules:')
    for module in modules:
        module.regs.sort(key=lambda reg: reg.address * 100 + reg.msb)
        print('============================================================================')
        print(module.toString())
        print('============================================================================')
        for reg in module.regs:
           print(reg.toString())

    print('Writing documentation file to ' + DOC_FILE.replace(".tex",SUFFIX+".tex"))
    writeDocFile (modules, DOC_FILE)

    print('Writing org file to ' + ORG_FILE.replace(".org",SUFFIX+".org"))
    writeOrgFile (modules, ORG_FILE)

    print('Writing constants file to ' + CONSTANTS_FILE.replace(".vhd",SUFFIX+".vhd"))
    writeConstantsFile(modules, CONSTANTS_FILE.replace(".vhd",SUFFIX+".vhd"))

    if (PACKAGE_FILE!=''):
        print('Writing package file to ' + PACKAGE_FILE)
        writePackageFile (modules, PACKAGE_FILE)

    for module in modules:
        if not module.isExternal:
            updateModuleFile(module)


    regs = {}
    for module in modules:
        for reg in module.regs:
            d = {"adr":  reg.address,
                 "permission": reg.permission,
                 "mask": reg.mask,
                 "description": reg.description}

            if CONFIG['TOP_NODE_NAME']=="DRS":
                d["adr8"] = reg.address*4

            print(d)

            regs[reg.name] = d


    with open(JSON_FILE, "w+") as outfile:
        outfile.write(json.dumps(regs, indent=4))

    if board_type == 'ctp7':
        writeStatusBashScript(modules, BASH_STATUS_SCRIPT_FILE)
        writeUHalAddressTable(modules, UHAL_ADDRESS_TABLE_FILE_CTP7, 0, num_of_oh)
    elif board_type == 'glib':
        writeUHalAddressTable(modules, UHAL_ADDRESS_TABLE_FILE_GLIB, GLIB_IPB_BASE_ADDRESS, num_of_oh)

def findRegisters(node, baseName, baseAddress, modules, currentModule, vars, isGenerated, num_of_oh):
    if (isGenerated == None or isGenerated == False) and node.get('generate') is not None and node.get('generate') == 'true':
        if node.get('generate_idx_var') == 'OH_IDX':
            generateSize = num_of_oh
            vars [node.get('generate_idx_var')+'_LOOP_SIZE'] = generateSize
        else:
            generateSize = parseInt(node.get('generate_size'))
            vars [node.get('generate_idx_var')+'_LOOP_SIZE'] = generateSize

        generateAddressStep = parseInt(node.get('generate_address_step'))
        generateIdxVar = node.get('generate_idx_var')

        for i in range(0, generateSize):

            vars[generateIdxVar] = i
            vars[generateIdxVar + "_STEP_SIZE"] = generateAddressStep
            #print('generate base_addr = ' + hex(baseAddress + generateAddressStep * i) + ' for node ' + node.get('id'))

            findRegisters(node, baseName, baseAddress + generateAddressStep * i, modules, currentModule, vars, True, num_of_oh)
        return

    isModule = node.get('fw_is_module') is not None and node.get('fw_is_module') == 'true'
    name = baseName
    module = currentModule
    if baseName != '':
        name += '.'

    if node.get('id') is not None:
        name += node.get('id')
    address = baseAddress

    if isModule:
        module = Module()
        module.name = substituteVars(name, vars)
        module.description = substituteVars(node.get('description'), vars)
        module.baseAddress = parseInt(node.get('address'))
        if node.get('fw_is_module_external') is not None and node.get('fw_is_module_external') == 'true':
            module.isExternal = True
        else:
            module.regAddressMsb = parseInt(node.get('fw_reg_addr_msb'))
            module.regAddressLsb = parseInt(node.get('fw_reg_addr_lsb'))
            module.file = node.get('fw_module_file')
            module.userClock = node.get('fw_user_clock_signal')
            module.busClock = node.get('fw_bus_clock_signal')
            module.busReset = node.get('fw_bus_reset_signal')
            module.masterBus = node.get('fw_master_bus_signal')
            module.slaveBus = node.get('fw_slave_bus_signal')
        if not module.isValid():
            error = 'One or more parameters for module ' + module.name + ' is missing... ' + module.toString()
            raise ValueError(error)

        # add a clone of the module as a parent node of that module
        parent                 = Register()
        parent.name            = substituteVars(name, vars)
        parent.name_raw        = name
        parent.description_raw = module.description
        parent.address         = 0
        parent.description     = module.description
        parent.description     = module.description
        parent.gensize         = {}
        parent.genvars         = {}
        parent.genstep         = {}

        module.addParent(parent)

        modules.append(module)

    else:

        if node.get('address') is not None:
            address = baseAddress + parseInt(node.get('address'))

        # need some way to discriminate parent nodes from endpoints
        if ( node.get('fw_signal')              is not None or
            ((node.get('permission')             is not None
            or node.get('mask')                   is not None
            or node.get ('fw_write_pulse_signal') is not None)
            and node.get('generate_size')         is     None
            and node.get('generate')              is     None
            and node.get('address')               is not None)
        ):
            reg = Register()
            reg.name = substituteVars(name, vars)
            reg.name_raw = name
            reg.address = address
            reg.description_raw = node.get('description')
            reg.description = substituteVars(node.get('description'), vars)
            reg.permission = node.get('permission')
            if node.get('mask') is None:
                reg.mask = 0xffffffff; # default to full 32bit mask if not specified
            else:
                reg.mask = parseInt(node.get('mask'))
            msb, lsb = getLowHighFromBitmask(reg.mask)
            reg.msb = msb
            reg.lsb = lsb

            global USED_REGISTER_SPACE

            global_address = address + module.baseAddress
            if (global_address in USED_REGISTER_SPACE):
                if reg.permission == "rw" and (USED_REGISTER_SPACE[global_address] & reg.mask) != 0:
                    error = 'Register write conflict on %s at address 0x%X' % (reg.name, global_address)
                    raise ValueError(error)
                else:
                    USED_REGISTER_SPACE[global_address] |= reg.mask
            else:
                USED_REGISTER_SPACE[global_address] = reg.mask

            reg.default = parseInt(node.get('fw_default'))
            if node.get('fw_signal') is not None:
                reg.signal = substituteVars(node.get('fw_signal'), vars)
            if node.get('fw_write_pulse_signal') is not None:
                reg.write_pulse_signal = substituteVars(node.get('fw_write_pulse_signal'), vars)
            if node.get('fw_write_done_signal') is not None:
                reg.write_done_signal = substituteVars(node.get('fw_write_done_signal'), vars)
            if node.get('fw_read_pulse_signal') is not None:
                reg.read_pulse_signal = substituteVars(node.get('fw_read_pulse_signal'), vars)
            if node.get('fw_read_ready_signal') is not None:
                reg.read_ready_signal = substituteVars(node.get('fw_read_ready_signal'), vars)


            ################################################################################
            # Counters
            ################################################################################

            if node.get('fw_cnt_en_signal') is not None:
                reg.fw_cnt_en_signal = substituteVars (node.get('fw_cnt_en_signal'),vars)
            if node.get('fw_make_signal') is not None:
                reg.fw_make_signal = substituteVars (node.get('fw_make_signal'),vars)
            if node.get('fw_cnt_reset_signal') is not None:
                reg.fw_cnt_reset_signal = substituteVars (node.get('fw_cnt_reset_signal'),vars)
            else:
                reg.fw_cnt_reset_signal = module.busReset
            if node.get('fw_cnt_snap_signal') is not None:
                reg.fw_cnt_snap_signal = substituteVars (node.get('fw_cnt_snap_signal'),vars)
            if node.get('fw_cnt_allow_rollover_signal') is not None:
                reg.fw_cnt_allow_rollover_signal = substituteVars (node.get('fw_cnt_allow_rollover_signal'),vars)
            if node.get('fw_cnt_increment_step_signal') is not None:
                reg.fw_cnt_increment_step_signal = substituteVars (node.get('fw_cnt_increment_step_signal'),vars)

            ################################################################################
            # Rate Counter
            ################################################################################

            if node.get('fw_rate_reset_signal') is not None:
                reg.fw_rate_reset_signal = substituteVars (node.get('fw_rate_reset_signal'),vars)
            else:
                reg.fw_rate_reset_signal = module.busReset

            if node.get('fw_rate_log') is not None:
                reg.fw_rate_log = substituteVars (node.get('fw_rate_log'),vars)
            if node.get('fw_rate_en_signal') is not None:
                reg.fw_rate_en_signal = substituteVars (node.get('fw_rate_en_signal'),vars)
            if node.get('fw_rate_clk_frequency') is not None:
                reg.fw_rate_clk_frequency = substituteVars (node.get('fw_rate_clk_frequency'),vars)
            if node.get('fw_rate_inc_width') is not None:
                reg.fw_rate_inc_width = substituteVars (node.get('fw_rate_inc_width'),vars)
            if node.get('fw_rate_progress_bar_width') is not None:
                reg.fw_rate_progress_bar_width = substituteVars (node.get('fw_rate_progress_bar_width'),vars)
            if node.get('fw_rate_progress_bar_step') is not None:
                reg.fw_rate_progress_bar_step = substituteVars (node.get('fw_rate_progress_bar_step'),vars)
            if node.get('fw_rate_speedup') is not None:
                reg.fw_rate_speedup = substituteVars (node.get('fw_rate_speedup'),vars)
            if node.get('fw_rate_progress_bar_signal') is not None:
                reg.fw_rate_progress_bar_signal = substituteVars (node.get('fw_rate_progress_bar_signal'),vars)

            ################################################################################
            # Error
            ################################################################################

            reg.gensize={}
            reg.genvars={}
            for varKey in vars.keys():
                if reg.name_raw.find("${" + varKey + "}") > 0:
                    reg.genvars [varKey] = vars[varKey]
                    reg.gensize [varKey] = vars[varKey + "_LOOP_SIZE"]
                    reg.genstep [varKey] = vars[varKey + "_STEP_SIZE"]

            if module is None:
                error = 'Module is not set, cannot add register ' + reg.name
                raise ValueError(error)
            if not reg.isValidReg(module.isExternal):
                raise ValueError('One or more attributes for register %s are missing.. %s' % (reg.name, reg.toString()))

            module.addReg(reg)

        elif (node.get('id') is not None):

            parent                 = Register()
            parent.name            = substituteVars(name, vars)
            parent.name_raw        = name
            parent.description_raw = node.get('description')
            parent.description     = substituteVars(node.get('description'), vars)

            parent.gensize={}
            parent.genvars={}
            parent.genstep={}

            for varKey in vars.keys():
                if parent.name_raw.find("${" + varKey + "}") > 0:

                    parent.genvars [varKey] = vars[varKey]
                    parent.gensize [varKey] = vars[varKey + "_LOOP_SIZE"]
                    parent.genstep [varKey] = vars[varKey + "_STEP_SIZE"]

            if (module is not None):
                module.addParent(parent)

    for child in node:
        findRegisters(child, name, address, modules, module, vars, False, num_of_oh)

def writeOrgFile (modules, filename):

    def convert_newlines(string):
        if string is None:
            string=""
        str = string.replace('\\n','|\n|            |      |         |     |     |  ')
        #str = str + "|"
        return str

    def write_module_name (f, module):
        module_name = module.name
        f.write ('\n')
        f.write ('* Module %s \t adr = ~0x%x~\n' % (module_name, module.baseAddress))
        f.write ('\n')
        f.write ('%s\n' % (module.description))
        f.write ('\n')

    def write_end_of_table (f):
        f.write('\n')

    def write_parent_name (f, parent_name):
        f.write('*%s*\n' % parent_name)
        f.write('\n')

    def write_parent_description (f, parent_description):
        f.write('%s\n' % parent_description.replace("\\\\","\n\n"))
        f.write('\n')

    def write_parent_generators (f, parent):

        def idx_to_xyz (idx):
            return idx.replace('GBT_IDX','GBT{N}').replace('OH_IDX','OH{X}').replace('VFAT_IDX','VFAT{Y}').replace('CHANNEL_IDX','CHANNEL{Z}')

        for varKey in parent.genvars.keys():
            f.write('Generated range of %s is ~[%d:0]~ adr_step = ~0x%X~ (%d)\n' % (idx_to_xyz(varKey), parent.gensize[varKey]-1, parent.genstep[varKey], parent.genstep[varKey]))

    def write_start_of_reg_table (f):
        f.write('|------------+-------+-------+---------+------+-----+----------------------------|\n')
        f.write('| Node       |  Adr  | Adr8  | Bits    | Perm | Def | Description                |\n')
        f.write('|------------+-------+-------+---------+------+-----+----------------------------|\n')

    def write_reg_entry (f, endpoint_name, address, bithi, bitlo, permission, default, description):

        #if "\\\\" in description:
        text = description.split("\\\\")


        if (default!="Pulsed"):
            if (permission!="r"):
                default = ("~%s~" % default)
        else:
            default="Pulse"

        bitstr = ("[%d:%d]" % (bithi, bitlo))
        if (bithi==bitlo):
            bitstr = ("%d" % (bithi))

        for i in range(0,len(text)):
            #print text
            if (i==0):
                f.write('|%s | ~0x%x~ | ~0x%x~ | ~%s~ | %s | %s | %s | \n' % (endpoint_name, address, address*4, bitstr, permission, default, convert_newlines(text[i])))
            else:
                f.write('|  |  |  |  |  |  |%s|\n' % text[i])
                print(text[i])
        f.write('|------------+---+---+---------+-----+-----+----------------------------|\n')

    def writeDoc (filename):

        f = filename

        for module in modules:

            print ("    > writing documentation for " + module.name)
            ################################################################################
            # Nodes to skip from documentation
            ################################################################################

            if module.name=="GEM_AMC.GLIB_SYSTEM":
                continue

            ################################################################################
            # Write module name
            ################################################################################

            write_module_name (f, module)

            ################################################################################

            # only want to write the table header and parent name once
            name_of_last_parent_node = ""

            ################################################################################
            # Loop over registers
            ################################################################################

            reg_is_first_in_parent = 1

            for reg in module.regs:

                # Only want to document the first instance in a loop of OH, VFAT, or Channel
                # allow other loops to unroll...

                is_first_in_loop = 1
                reg_unrolling_is_supressed = 0
                for varKey in reg.genvars.keys():
                    if (varKey == "GBT_IDX" or varKey == "OH_IDX" or varKey == "VFAT_IDX" or varKey == "CHANNEL_IDX"):
                        reg_unrolling_is_supressed = 1
                        if (reg.genvars[varKey] > 0):
                            is_first_in_loop = 0

                if (is_first_in_loop == 0):
                    continue

                name          = reg.name
                name_split    = reg.name_raw.split('.')
                address       = reg.address + module.baseAddress


                endpoint_name = reg.name.split('.')[-1]

                name_of_parent_node = ""

                # find the name of the current node's parent

                for i in range (len(name_split)-1):
                    name_of_parent_node = name_of_parent_node + name_split[i]
                    if (i!=(len(name_split)-2)):
                        name_of_parent_node = name_of_parent_node + "."

                # find the parent module
                reg_parent = Register()
                parent_found = 0
                for parent in module.parents:
                    if name_of_parent_node==parent.name_raw:
                        reg_parent=parent
                        parent_found = 1

                # error if we can't find the parent

                if (not parent_found):
                    raise ValueError("Somethings wrong... parent not found for node %s" % name);

                # write a header if this is a new parent

                if (name_of_parent_node != name_of_last_parent_node):

                    if (not reg_is_first_in_parent):
                        write_end_of_table(f)

                    reg_is_first_in_parent = 0

                    vars = { 'GBT_IDX' : '{N}' , 'OH_IDX' : '{X}' , 'VFAT_IDX' : '{Y}', 'CHANNEL_IDX' : '{Z}' }

                    # Write name of parent node
                    write_parent_name (f, substituteVars(reg_parent.name_raw, vars))

                    # If parent has a description, write it
                    if (reg_parent.description!="" and reg_parent.description!=None):
                        write_parent_description (f, substituteVars(reg_parent.description_raw, vars))

                    # If parent is a generator, record generation properties
                    if (len(reg_parent.genvars)>0):
                        write_parent_generators (f, reg_parent)

                    # write the reg table preampble
                    write_start_of_reg_table (f)

                name_of_last_parent_node = name_of_parent_node

                reg_default=""

                if (reg.default!=None):
                    if (reg.default==-1):
                        reg_default = ""
                    else:
                        reg_default = "0x%X" % reg.default
                if (reg.write_pulse_signal!=None):
                    reg_default = "Pulsed"

                description=""
                if (reg_unrolling_is_supressed ):
                    description=substituteVars(reg.description_raw,vars)
                else:
                    description=reg.description

                if (description is None):
                    description=""

                # write register entry
                write_reg_entry (f, endpoint_name, address, reg.msb, reg.lsb, reg.permission, reg_default, description)

            # end of table

            write_end_of_table (f)

        print ("    > finished writing all documentation...")

    MARKER_START = "# START: ADDRESS_TABLE :: DO NOT EDIT"
    MARKER_END   = "# END: ADDRESS_TABLE :: DO NOT EDIT"

    outfile = filename.replace(".org",SUFFIX+".org")
    insert_code (filename, outfile, MARKER_START, MARKER_END, writeDoc)

def writeDocFile (modules, filename):

    def latexify(string):
        if string is None:
            string=""
        return string.replace('\\\\','\\\\\\\\').replace('&','\&').replace('%','\%').replace('$','\$').replace('#','\#').replace('_','\_').replace('{','\{').replace('}','\}').replace('~','\~').replace('^','\^')

    def convert_newlines(string):
        if string is None:
            string=""
        return string.replace('\\n','\\\\ & & & & &')

    def write_module_name_latex (f, module):
        padding = "    "
        module_name = module.name
        f.write ('\n')
        f.write ('%s\pagebreak\n' % (padding))
        f.write ('%s\\section{Module: %s \\hfill \\texttt{0x%x}}\n' % (padding, latexify(module_name), module.baseAddress))
        f.write ('\n')
        f.write ('%s%s\\\\\n' % (padding, latexify(module.description)))
        f.write ('\n')
        f.write ('%s\\renewcommand{\\arraystretch}{1.3}\n' % (padding))

    def write_end_of_table_latex (f):
        padding = "    "
        f.write('%s\\end{tabularx}\n' % (padding))
        f.write('%s\\vspace{5mm}\n' % (padding))
        f.write('\n\n')

    def write_parent_name_latex (f, parent_name):
        padding = "    "
        f.write('%s\\noindent\n' % (padding))
        f.write('%s\\subsection*{\\textcolor{parentcolor}{\\textbf{%s}}}\n' % (padding, latexify(parent_name)))
        f.write ('\n')

    def write_parent_description_latex (f, parent_description):
        padding = "    "
        f.write('%s\\vspace{4mm}\n' % (padding))
        f.write('%s\\noindent\n' % (padding))
        f.write('%s%s\n' % (padding, latexify(parent_description)))
        f.write('%s\\noindent\n' % (padding))
        f.write('\n')

    def write_parent_generators_latex (f, parent):

        def idx_to_xyz (idx):
            return idx.replace('GBT_IDX','GBT{N}').replace('OH_IDX','OH{X}').replace('VFAT_IDX','VFAT{Y}').replace('CHANNEL_IDX','CHANNEL{Z}')

        padding = "    "
        f.write ('%s\\noindent\n' % (padding) )
        f.write ('%s\\keepXColumns\n' % (padding))
        f.write ('%s\\begin{tabularx}{\\linewidth}{  l  l  l  r   X }\n' % (padding))
        for varKey in parent.genvars.keys():
            f.write('%sGenerated range of & %s & is & \\texttt{[%d:0]} & adr\_step=0x%X (%d) \\\\ \n' % (padding,  latexify(idx_to_xyz(varKey)), parent.gensize[varKey]-1, parent.genstep[varKey], parent.genstep[varKey]))
        f.write('%s\\end{tabularx}\n' % (padding))

    def write_start_of_reg_table_latex (f):
        padding = "    "
        f.write ('%s\\keepXColumns\n' % (padding))
        f.write ('%s\\begin{tabularx}{\\linewidth}{ | l | l | r | c | l | X | }\n' % (padding))
        f.write('%s\\hline\n' % (padding))
        f.write('%s\\textbf{Node} & \\textbf{Adr} & \\textbf{Bits} & \\textbf{Perm} & \\textbf{Def} & \\textbf{Description} \\\\\\hline\n' % (padding))
        f.write('%s\\nopagebreak\n' % (padding))

    def write_reg_entry_latex (f, endpoint_name, address, bithi, bitlo, permission, default, description):

        padding = "    "
        if (default!="Pulsed"):
            default = "\\texttt{%s}" % default
        else:
            default="Pulse"

        f.write('%s%s & \\texttt{0x%x} & \\texttt{[%d:%d]} & %s & %s & %s \\\\\hline\n' % (padding,latexify(endpoint_name), address, bithi, bitlo, permission, default, convert_newlines(latexify(description))))

    def writeDoc (filename):

        f = filename

        padding = "    "


        for module in modules:

            print ("    > writing documentation for " + module.name)
            ################################################################################
            # Nodes to skip from documentation
            ################################################################################

            if module.name=="GEM_AMC.GLIB_SYSTEM":
                continue

            ################################################################################
            # Write module name
            ################################################################################

            write_module_name_latex (f, module)

            ################################################################################

            # only want to write the table header and parent name once
            name_of_last_parent_node = ""

            ################################################################################
            # Loop over registers
            ################################################################################

            reg_is_first_in_parent = 1

            for reg in module.regs:

                # Only want to document the first instance in a loop of OH, VFAT, or Channel
                # allow other loops to unroll...

                is_first_in_loop = 1
                reg_unrolling_is_supressed = 0
                for varKey in reg.genvars.keys():
                    if (varKey == "GBT_IDX" or varKey == "OH_IDX" or varKey == "VFAT_IDX" or varKey == "CHANNEL_IDX"):
                        reg_unrolling_is_supressed = 1
                        if (reg.genvars[varKey] > 0):
                            is_first_in_loop = 0

                if (is_first_in_loop == 0):
                    continue

                name          = reg.name
                name_split    = reg.name_raw.split('.')
                address       = reg.address + module.baseAddress


                endpoint_name = reg.name.split('.')[-1]

                name_of_parent_node = ""

                # find the name of the current node's parent

                for i in range (len(name_split)-1):
                    name_of_parent_node = name_of_parent_node + name_split[i]
                    if (i!=(len(name_split)-2)):
                        name_of_parent_node = name_of_parent_node + "."

                # find the parent module
                reg_parent = Register()
                parent_found = 0
                for parent in module.parents:
                    if name_of_parent_node==parent.name_raw:
                        reg_parent=parent
                        parent_found = 1

                # error if we can't find the parent

                if (not parent_found):
                    raise ValueError("Somethings wrong... parent not found for node %s" % name);

                # write a header if this is a new parent

                if (name_of_parent_node != name_of_last_parent_node):

                    if (not reg_is_first_in_parent):
                        write_end_of_table_latex(f)

                    reg_is_first_in_parent = 0

                    vars = { 'GBT_IDX' : '{N}' , 'OH_IDX' : '{X}' , 'VFAT_IDX' : '{Y}', 'CHANNEL_IDX' : '{Z}' }

                    # Write name of parent node
                    write_parent_name_latex (f, substituteVars(reg_parent.name_raw, vars))

                    # If parent has a description, write it
                    if (reg_parent.description!="" and reg_parent.description!=None):
                        write_parent_description_latex (f, substituteVars(reg_parent.description_raw, vars))

                    # If parent is a generator, record generation properties
                    if (len(reg_parent.genvars)>0):
                        write_parent_generators_latex (f, reg_parent)

                    # write the reg table preampble
                    write_start_of_reg_table_latex (f)

                name_of_last_parent_node = name_of_parent_node

                reg_default=""

                if (reg.default!=None):
                    if (reg.default==-1):
                        reg_default = ""
                    else:
                        reg_default = "0x%X" % reg.default
                if (reg.write_pulse_signal!=None):
                    reg_default = "Pulsed"

                description=""
                if (reg_unrolling_is_supressed ):
                    description=substituteVars(reg.description_raw,vars)
                else:
                    description=reg.description

                # write register entry
                write_reg_entry_latex (f, endpoint_name, address, reg.msb, reg.lsb, reg.permission, reg_default, description)

            # end of table

            write_end_of_table_latex (f)

        print ("    > finished writing all documentation...")

    MARKER_START = "% START: ADDRESS_TABLE :: DO NOT EDIT"
    MARKER_END   = "% END: ADDRESS_TABLE :: DO NOT EDIT"

    outfile = filename.replace(".tex",SUFFIX+".tex")
    insert_code (filename, outfile, MARKER_START, MARKER_END, writeDoc)

def writePackageFile (modules, filename):

    def writeIPBusSlaves (filename):

        f = filename

        padding = "    "

        imodule=0
        f.write('%stype t_ipb_slv is record\n'             % (padding))
        for module in modules:
            f.write('%s    %15s   : integer;\n'            % (padding, module.getVhdlName()))
            imodule = imodule + 1
        f.write('%send record;\n'                          % (padding))

        imodule=0
        f.write('%s-- IPbus slave index definition\n'      % (padding))
        f.write('%sconstant IPB_SLAVE : t_ipb_slv := (\n'  % (padding))
        for module in modules:
            if (imodule != 0):
                f.write(',\n')
            f.write('%s    %15s  => %d'                 % (padding, module.getVhdlName(), imodule))
            imodule = imodule + 1
        f.write('%s);\n'                                   % (padding))

    def writeIPBusAddrSel (filename):

        f = filename

        padding = "        "
        modulebits = 4

        imodule = 0

        for module in modules:

            if (imodule==0):
                start = "if   "
            else:
                start = "elsif"

            f.write('%s%s(std_match(addr(15 downto 0), std_logic_vector(to_unsigned(IPB_SLAVE.%15s,     %d))  & "------------")) then sel := IPB_SLAVE.%s;\n' % (padding, start, module.getVhdlName(), modulebits, module.getVhdlName()))

            imodule = imodule + 1

    MARKER_START = "-- START: IPBUS_SLAVES :: DO NOT EDIT"
    MARKER_END   = "-- END: IPBUS_SLAVES :: DO NOT EDIT"
    insert_code (filename, filename, MARKER_START, MARKER_END, writeIPBusSlaves)

    MARKER_START = "-- START: IPBUS_ADDR_SEL :: DO NOT EDIT"
    MARKER_END   = "-- END: IPBUS_ADDR_SEL :: DO NOT EDIT"
    insert_code (filename, filename, MARKER_START, MARKER_END, writeIPBusAddrSel)


def writeConstantsFile(modules, filename):
    f = io.open (filename, "w", newline='', encoding="utf-8")
    f.write('library IEEE;\n'\
            'use IEEE.STD_LOGIC_1164.all;\n\n')
    f.write('-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----\n')
    f.write('package registers is\n')

    for module in modules:
        if module.isExternal:
            continue

        totalRegs32 = getNumRequiredRegs32(module)

        # check if we have enough address bits for the max reg address (recall that the reg list is sorted by address)
        topAddressBinary = "{0:#0b}".format(module.regs[-1].address)
        numAddressBitsNeeded = len(topAddressBinary) - 2
        print('    > Top address of the module ' + module.getVhdlName() + ' is ' + hex(module.regs[-1].address) + ' (' + topAddressBinary + '), need ' + str(numAddressBitsNeeded) + ' bits and have ' + str(module.regAddressMsb - module.regAddressLsb + 1) + ' bits available')
        if numAddressBitsNeeded > module.regAddressMsb - module.regAddressLsb + 1:
            raise ValueError('There is not enough bits in the module address space to accomodate all registers (see above for details). Please modify fw_reg_addr_msb and/or fw_reg_addr_lsb attributes in the xml file')


        f.write('\n')
        f.write('    --============================================================================\n')
        f.write('    --       >>> ' + module.getVhdlName() + ' Module <<<    base address: ' + hexPadded32(module.baseAddress) + '\n')
        f.write('    --\n')
        for line in tw.wrap(module.description, 75):
            f.write('    -- ' + line + '\n')
        f.write('    --============================================================================\n\n')

        f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_NUM_REGS : integer := ' + str(totalRegs32) + ';\n')
        f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_MSB : integer := ' + str(module.regAddressMsb) + ';\n')
        f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_LSB : integer := ' + str(module.regAddressLsb) + ';\n')
        #f.write('    type T_' + VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_ARR is array(integer range <>) of std_logic_vector(%s downto %s);\n\n' % (VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_MSB', VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_LSB')) # cannot use that because we need to be able to pass it as a generic type to the generic IPBus slave module

        for reg in module.regs:
            #print('Writing register constants for ' + reg.name)
            f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_ADDR    : '\
                        'std_logic_vector(' + str(module.regAddressMsb) + ' downto ' + str(module.regAddressLsb) + ') := ' + \
                        vhdlHexPadded(reg.address, module.regAddressMsb - module.regAddressLsb + 1)  + ';\n')
            if reg.msb == reg.lsb:
                f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_BIT    : '\
                            'integer := ' + str(reg.msb) + ';\n')
            else:
                f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_MSB    : '\
                            'integer := ' + str(reg.msb) + ';\n')
                f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_LSB     : '\
                            'integer := ' + str(reg.lsb) + ';\n')
            if (reg.default==-1):
                f.write('  --constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_DEFAULT should be supplied externally\n')
            elif reg.default is not None and reg.msb - reg.lsb > 0:
                f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_DEFAULT : '\
                            'std_logic_vector(' + str(reg.msb) + ' downto ' + str(reg.lsb) + ') := ' + \
                            vhdlHexPadded(reg.default, reg.msb - reg.lsb + 1)  + ';\n')
            elif reg.default is not None and reg.msb - reg.lsb == 0:
                f.write('    constant ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_DEFAULT : '\
                            'std_logic := ' + \
                            vhdlHexPadded(reg.default, reg.msb - reg.lsb + 1)  + ';\n')
            f.write('\n')

    f.write('\n')
    f.write('end registers;\n')
    f.close()

def updateModuleFile(module):

    if module.isExternal:
        return

    totalRegs32 = getNumRequiredRegs32(module)
    print('Updating ' + module.name + ' module in file = ' + module.file)

    # copy lines out of source file
    f = io.open(module.file, 'r+', encoding="utf-8")
    lines = f.readlines()
    f.close()

    # create temp file for writing to
    tempname = tempfile.mktemp()
    shutil.copy (module.file, tempname)
    f = io.open (tempname, "w", newline='', encoding="utf-8")

    signalSectionFound = False
    signalSectionDone = False
    slaveSectionFound = False
    slaveSectionDone = False
    registersLibraryFound = False
    for line in lines:
        #line = unicode(line) # str to unicode
        if line.startswith('use work.registers.all;'):
            registersLibraryFound = True

        # if we're outside of business of writing the special sections, then just repeat the lines we read from the original file
        if (not signalSectionFound or signalSectionDone) and (not slaveSectionFound or slaveSectionDone):
            f.write(line)
        elif (signalSectionFound and not signalSectionDone and VHDL_REG_SIGNAL_MARKER_END in line):
            signalSectionDone = True
            f.write(line)
        elif (slaveSectionFound and not slaveSectionDone and VHDL_REG_SLAVE_MARKER_END in line):
            slaveSectionDone = True
            f.write(line)

        # signal section
        if VHDL_REG_SIGNAL_MARKER_START in line:
            signalSectionFound = True
            signalDeclaration         = "  signal regs_read_arr        : t_std32_array(<num_regs> - 1 downto 0) := (others => (others => '0'));\n"\
                                        "  signal regs_write_arr       : t_std32_array(<num_regs> - 1 downto 0) := (others => (others => '0'));\n"\
                                        "  signal regs_addresses       : t_std32_array(<num_regs> - 1 downto 0) := (others => (others => '0'));\n"\
                                        "  signal regs_defaults        : t_std32_array(<num_regs> - 1 downto 0) := (others => (others => '0'));\n"\
                                        "  signal regs_read_pulse_arr  : std_logic_vector(<num_regs> - 1 downto 0) := (others => '0');\n"\
                                        "  signal regs_write_pulse_arr : std_logic_vector(<num_regs> - 1 downto 0) := (others => '0');\n"\
                                        "  signal regs_read_ready_arr  : std_logic_vector(<num_regs> - 1 downto 0) := (others => '1');\n" \
                                        "  signal regs_write_done_arr  : std_logic_vector(<num_regs> - 1 downto 0) := (others => '1');\n" \
                                        "  signal regs_writable_arr    : std_logic_vector(<num_regs> - 1 downto 0) := (others => '0');\n"
            signalDeclaration = signalDeclaration.replace('<num_regs>', VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_NUM_REGS')
            f.write(signalDeclaration)

            # connect counter en signal declarations
            header_written = False;
            for reg in module.regs:
                if reg.fw_cnt_en_signal is not None and reg.signal is not None:
                    if (not header_written):
                        f.write('    -- Connect counter signal declarations\n')
                        header_written = True;
                    if (reg.fw_make_signal != "false"):
                        f.write ('  signal %s : std_logic_vector (%s downto 0) := (others => \'0\');\n' % (reg.signal,  reg.msb-reg.lsb))

            header_written = False;
            for reg in module.regs:
                if reg.fw_rate_en_signal is not None and reg.signal is not None:
                    if (not header_written):
                        f.write('    -- Connect rate signal declarations\n')
                        header_written = True;
                    f.write ('  signal %s : std_logic_vector (%s downto 0) := (others => \'0\');\n' % (reg.signal,  reg.msb-reg.lsb))

        # slave section
        if VHDL_REG_SLAVE_MARKER_START in line:
            slaveSectionFound = True
            slaveDeclaration =  '  ipbus_slave_inst : entity work.ipbus_slave_tmr\n'\
                                '      generic map(\n'\
                                '         g_ENABLE_TMR           => %s,\n' % ('EN_TMR_IPB_SLAVE_'     + module.getVhdlName()) + \
                                '         g_NUM_REGS             => %s,\n' % (VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_NUM_REGS') + \
                                '         g_ADDR_HIGH_BIT        => %s,\n' % (VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_MSB') + \
                                '         g_ADDR_LOW_BIT         => %s,\n' % (VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_LSB') + \
                                '         g_USE_INDIVIDUAL_ADDRS => true\n'\
                                '     )\n'\
                                '     port map(\n'\
                                '         ipb_reset_i            => %s,\n' % (module.busReset) + \
                                '         ipb_clk_i              => %s,\n' % (module.busClock) + \
                                '         ipb_mosi_i             => %s,\n' % (module.masterBus) + \
                                '         ipb_miso_o             => %s,\n' % (module.slaveBus) + \
                                '         usr_clk_i              => %s,\n' % (module.userClock) + \
                                '         regs_read_arr_i        => regs_read_arr,\n'\
                                '         regs_write_arr_o       => regs_write_arr,\n'\
                                '         read_pulse_arr_o       => regs_read_pulse_arr,\n'\
                                '         write_pulse_arr_o      => regs_write_pulse_arr,\n'\
                                '         regs_read_ready_arr_i  => regs_read_ready_arr,\n'\
                                '         regs_write_done_arr_i  => regs_write_done_arr,\n'\
                                '         individual_addrs_arr_i => regs_addresses,\n'\
                                '         regs_defaults_arr_i    => regs_defaults,\n'\
                                '         writable_regs_i        => regs_writable_arr\n'\
                                '    );\n'

            f.write('\n')
            f.write('    -- IPbus slave instanciation\n')
            f.write(slaveDeclaration)
            f.write('\n')

            # assign addresses
            uniqueAddresses = []
            for reg in module.regs:
                if not reg.address in uniqueAddresses:
                    uniqueAddresses.append(reg.address)
            if len(uniqueAddresses) != totalRegs32:
                raise ValueError("Something's worng.. Got a list of unique addresses which is of different length than the total number of 32bit addresses previously calculated..");

            f.write('  -- Addresses\n')
            for i in range(0, totalRegs32):
                f.write('  regs_addresses(%d)(%s downto %s) <= %s;\n' % (i, VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_MSB', VHDL_REG_CONSTANT_PREFIX + module.getVhdlName() + '_ADDRESS_LSB', vhdlHexPadded(uniqueAddresses[i], module.regAddressMsb - module.regAddressLsb + 1))) # TODO: this is a hack using literal values - you should sort it out in the future and use constants (the thing is that the register address constants are not good for this since there are more of them than there are 32bit registers, so you need a constant for each group of regs that go to the same 32bit reg)
            f.write('\n')

            # connect read signals
            f.write('  -- Connect read signals\n')
            for reg in module.regs:
                isSingleBit = reg.msb == reg.lsb
                if 'r' in reg.permission:
                    f.write('  regs_read_arr(%d)(%s) <= %s;\n' % (uniqueAddresses.index(reg.address), VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_BIT' if isSingleBit else VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_MSB' + ' downto ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_LSB', reg.signal))

            f.write('\n')

            # connect write signals
            f.write('  -- Connect write signals\n')
            for reg in module.regs:
                isSingleBit = reg.msb == reg.lsb
                if 'w' in reg.permission and reg.signal is not None:
                    f.write('  %s <= regs_write_arr(%d)(%s);\n' % (reg.signal, uniqueAddresses.index(reg.address), VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_BIT' if isSingleBit else VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_MSB' + ' downto ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_LSB'))

            f.write('\n')

            # connect write pulse signals
            writePulseAddresses = []
            duplicateWritePulseError = False
            f.write('  -- Connect write pulse signals\n')
            for reg in module.regs:
                if 'w' in reg.permission and reg.write_pulse_signal is not None:
                    if uniqueAddresses.index(reg.address) in writePulseAddresses:
                        duplicateWritePulseError = True
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                        f.write(" !!! ERROR: register #" + str(uniqueAddresses.index(reg.address)) + " in module " + module.name + " is used for multiple write pulses (there can only be one write pulse per register address)\n")
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                    writePulseAddresses.append(uniqueAddresses.index(reg.address))
                    f.write('  %s <= regs_write_pulse_arr(%d);\n' % (reg.write_pulse_signal, uniqueAddresses.index(reg.address)))

            f.write('\n')

            # connect write done signals
            writeDoneAddresses = []
            duplicateWriteDoneError = False
            f.write('  -- Connect write done signals\n')
            for reg in module.regs:
                if 'w' in reg.permission and reg.write_done_signal is not None:
                    if uniqueAddresses.index(reg.address) in writeDoneAddresses:
                        duplicateWriteDoneError = True
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                        f.write(" !!! ERROR: register #" + str(uniqueAddresses.index(reg.address)) + " in module " + module.name + " is used for multiple write done signals (there can only be one write done signal per register address)\n")
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                    writeDoneAddresses.append(uniqueAddresses.index(reg.address))
                    f.write('  regs_write_done_arr(%d) <= %s;\n' % (uniqueAddresses.index(reg.address), reg.write_done_signal))

            f.write('\n')

            # connect read pulse signals
            readPulseAddresses = []
            duplicateReadPulseError = False
            f.write('  -- Connect read pulse signals\n')
            for reg in module.regs:
                if 'r' in reg.permission and reg.read_pulse_signal is not None:
                    if uniqueAddresses.index(reg.address) in readPulseAddresses:
                        duplicateReadPulseError = True
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                        f.write(" !!! ERROR: register #" + str(uniqueAddresses.index(reg.address)) + " in module " + module.name + " is used for multiple read pulses (there can only be one read pulse per register address)\n")
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                    readPulseAddresses.append(uniqueAddresses.index(reg.address))
                    f.write('  %s <= regs_read_pulse_arr(%d);\n' % (reg.read_pulse_signal, uniqueAddresses.index(reg.address)))

            f.write('\n')

           # connect counter signals
            f.write('  -- Connect counter instances\n')
            for reg in module.regs:

                # COUNTER WITH SNAP
                if (reg.fw_cnt_en_signal is not None):
                    f.write ("\n")
                    f.write ('  COUNTER_%s : entity work.counter_snap\n' % (reg.getVhdlName()))
                    f.write ('  generic map (\n')
                    if (reg.fw_cnt_increment_step!='1'):
                        f.write ('      g_INCREMENT_STEP => %s,\n' % (reg.fw_cnt_increment_step))
                    if (reg.fw_cnt_allow_rollover!='false'):
                        f.write ('      g_ALLOW_ROLLOVER => %s,\n' % (reg.fw_cnt_allow_rollover))
                    f.write ('      g_COUNTER_WIDTH  => %s\n' % (reg.msb - reg.lsb + 1))
                    f.write ('  )\n')
                    f.write ('  port map (\n')
                    f.write ('      ref_clk_i => %s,\n' % (module.userClock))
                    f.write ('      reset_i   => %s,\n' % (reg.fw_cnt_reset_signal))
                    f.write ('      en_i      => %s,\n' % (reg.fw_cnt_en_signal))
                    f.write ('      snap_i    => %s,\n' % (reg.fw_cnt_snap_signal))
                    f.write ('      count_o   => %s\n'  % (reg.signal))
                    f.write ('  );\n')
                    f.write ('\n')

                # COUNTER WITHOUT SNAP
                elif reg.fw_cnt_en_signal is not None:
                    f.write ("\n")
                    f.write ('  COUNTER_%s : entity work.counter\n' % (reg.getVhdlName()))
                    f.write ('  generic map (\n')
                    if (reg.fw_cnt_increment_step!='1'):
                        f.write ('      g_INCREMENT_STEP => %s,\n' % (reg.fw_cnt_increment_step))
                    if (reg.fw_cnt_allow_rollover!='false'):
                        f.write ('      g_ALLOW_ROLLOVER => %s,\n' % (reg.fw_cnt_allow_rollover))
                    f.write ('      g_COUNTER_WIDTH  => %s\n' % (reg.msb - reg.lsb + 1))
                    f.write ('  )\n')
                    f.write ('  port map (\n')
                    f.write ('      ref_clk_i => %s,\n' % (module.userClock))
                    f.write ('      reset_i   => %s,\n' % (reg.fw_cnt_reset_signal))
                    f.write ('      en_i      => %s,\n' % (reg.fw_cnt_en_signal))
                    f.write ('      count_o   => %s\n'  % (reg.signal))
                    f.write ('  );\n')
                    f.write ('\n')

            f.write('\n')

           # connect rate signals
            f.write('  -- Connect rate instances\n')
            for reg in module.regs:

                if reg.fw_rate_en_signal is not None:
                    f.write ("\n")
                    f.write ('  RATE_CNT_%s : entity work.rate_counter\n' % (reg.getVhdlName()))
                    f.write ('  generic map (\n')
                    f.write ('      g_COUNTER_WIDTH      => %s,\n' % (reg.msb - reg.lsb + 1))
                    f.write ('      g_CLK_FREQUENCY      => %s,\n' % (reg.fw_rate_clk_frequency))
                    f.write ('  )\n')
                    f.write ('  port map (\n')
                    f.write ('      clk_i                => %s,\n' % (module.userClock))
                    f.write ('      reset_i              => %s,\n' % (reg.fw_rate_reset_signal))
                    f.write ('      en_i                 => %s,\n' % (reg.fw_rate_en_signal))
                    f.write ('      rate_o               => %s\n'  % (reg.signal))
                    f.write ('  );\n')
                    f.write ('\n')

            f.write('\n')

            # connect read ready signals
            readReadyAddresses = []
            duplicateReadReadyError = False
            f.write('  -- Connect read ready signals\n')
            for reg in module.regs:
                if 'r' in reg.permission and reg.read_ready_signal is not None:
                    if uniqueAddresses.index(reg.address) in readReadyAddresses:
                        duplicateReadReadyError = True
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                        f.write(" !!! ERROR: register #" + str(uniqueAddresses.index(reg.address)) + " in module " + module.name + " is used for multiple read ready signals (there can only be one read ready signal per register address)\n")
                        f.write(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n")
                    readReadyAddresses.append(uniqueAddresses.index(reg.address))
                    f.write('    regs_read_ready_arr(%d) <= %s;\n' % (uniqueAddresses.index(reg.address), reg.read_ready_signal))

            f.write('\n')

            # Defaults
            f.write('  -- Defaults\n')
            writableRegAddresses = []
            for reg in module.regs:
                isSingleBit = reg.msb == reg.lsb
                if reg.default is not None:
                    if not uniqueAddresses.index(reg.address) in writableRegAddresses:
                        writableRegAddresses.append(uniqueAddresses.index(reg.address))
                    f.write('  regs_defaults(%d)(%s) <= %s;\n' % (uniqueAddresses.index(reg.address), VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_BIT' if isSingleBit else VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_MSB' + ' downto ' + VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_LSB', VHDL_REG_CONSTANT_PREFIX + reg.getVhdlName() + '_DEFAULT'))

            f.write('\n')

            # Writable regs
            # connect read ready signals
            f.write('  -- Define writable regs\n')
            for regAddr in writableRegAddresses:
                    f.write("  regs_writable_arr(%d) <= '1';\n" % (regAddr))

            f.write('\n')

    f.close()
    print((module.file).replace(".vhd",SUFFIX+".vhd"))
    shutil.copy (tempname, (module.file).replace(".vhd",SUFFIX+".vhd"))

    if not signalSectionFound or not signalSectionDone:
        print('--> ERROR <-- Could not find a signal section in the file.. Please include "' + VHDL_REG_SIGNAL_MARKER_START + '" and "' + VHDL_REG_SIGNAL_MARKER_END + '" comments denoting the area where the generated code will be inserted')
        print('        e.g. someting like that would work and look nice:')
        print('        ' + VHDL_REG_SIGNAL_MARKER_START + ' ' + VHDL_REG_GENERATED_DISCLAIMER)
        print('        ' + VHDL_REG_SIGNAL_MARKER_END + ' ----------------------------------------------')
        raise ValueError('No signal declaration markers found in %s -- see above' % module.file)

    if not slaveSectionFound or not slaveSectionDone:
        print('--> ERROR <-- Could not find a slave section in the file.. Please include "' + VHDL_REG_SLAVE_MARKER_START + '" and "' + VHDL_REG_SLAVE_MARKER_END + '" comments denoting the area where the generated code will be inserted')
        print('        e.g. someting like that would work and look nice:')
        print('        --===============================================================================================')
        print('        -- ' + VHDL_REG_GENERATED_DISCLAIMER)
        print('        ' + VHDL_REG_SLAVE_MARKER_START + ' ' + '==========================================================================')
        print('        ' + VHDL_REG_SLAVE_MARKER_END + ' ============================================================================')
        raise ValueError('No slave markers found in %s -- see above' % module.file)

    if not registersLibraryFound:
        raise ValueError('Registers library not included in %s -- please add "use work.registers.all;"' % module.file)

    if duplicateWritePulseError:
        raise ValueError("Two or more write pulse signals in module %s are associated with the same register address (only one write pulse per reg address is allowed), more details are printed to the module file" % module.file)
    if duplicateWriteDoneError:
        raise ValueError("Two or more write done signals in module %s are associated with the same register address (only one write done signal per reg address is allowed), more details are printed to the module file" % module.file)
    if duplicateReadPulseError:
        raise ValueError("Two or more read pulse signals in module %s are associated with the same register address (only one read pulse per reg address is allowed), more details are printed to the module file" % module.file)
    if duplicateReadReadyError:
        raise ValueError("Two or more read ready signals in module %s are associated with the same register address (only one read ready signal per reg address is allowed), more details are printed to the module file" % module.file)

# prints out bash scripts for quick and dirty testing in CTP7 linux (TODO: compile and install python there and write a nice command line interface which would use the address table (something like acm13tool with reg names autocomplete would be cool)
def writeStatusBashScript(modules, filename):
    print('Writing CTP7 status bash script')

    f = io.open(filename, 'w', encoding="utf-8")

    f.write('#!/bin/sh\n\n')
    f.write('MODULE=$1\n')

    f.write('if [ -z "$MODULE" ]; then\n')
    f.write('    echo "Usage: this_script.sh <module_name>"\n')
    f.write('    echo "Available modules:"\n')
    for module in modules:
        f.write('    echo "%s"' % module.name.replace(TOP_NODE_NAME + '.', ''))
    f.write('    exit\n')
    f.write('fi\n\n')

    for module in modules:
        f.write('if [ "$MODULE" = "%s" ]; then\n' % module.name.replace(TOP_NODE_NAME + '.', ''))
        for reg in module.regs:
            if 'r' in reg.permission:
                if reg.mask == 0xffffffff:
                    f.write("    printf '" + reg.name.ljust(45) + " = 0x%x\\n' `mpeek " + hex(AXI_IPB_BASE_ADDRESS + ((module.baseAddress + reg.address) << 2)) + "` \n")
                else:
                    f.write("    printf '" + reg.name.ljust(45) + " = 0x%x\\n' $(( (`mpeek " + hex(AXI_IPB_BASE_ADDRESS + ((module.baseAddress + reg.address) << 2)) + "` & " + hexPadded32(reg.mask) + ") >> " + str(reg.lsb) + " ))\n")
        f.write('fi\n\n')

    f.close()
    shutil.copy (tempname, module.file)

def writeUHalAddressTable(modules, filename, addrOffset, num_of_oh = None):
    print('Writing uHAL address table XML')

    rw_reg.parseXML(ADDRESS_TABLE_TOP, num_of_oh)
    top = rw_reg.getNode('GEM_AMC')

    # AMC specific nodes
    f = io.open("%s_amc.xml"%(filename), 'w', encoding="utf-8")
    f.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
    f.write('<node id="top">\n')
    printNodeToUHALFile(top, f, 1, 0, None, addrOffset)
    f.write('</node>\n')
    f.close()

    # OH specific nodes
    for oh in range(num_of_oh):
        f = io.open("%s_link%02d.xml"%(filename,oh), 'w', encoding="utf-8")
        f.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
        f.write('<node id="top">\n')
        printNodeToUHALFile(top, f, 1, 0, None, addrOffset, oh)
        f.write('</node>\n')
        f.close()
        pass
    pass

def printNodeToUHALFile(node, file, level, baseAddress, baseName, addrOffset, num_of_oh=None):
    amcTopNodesToSkip = ["GEM_AMC.OH"]

    ohTopNodesToSkip = [
        "GEM_AMC.TTC",
        "GEM_AMC.TRIGGER.CTRL",
        "GEM_AMC.TRIGGER.STATUS",
        "GEM_AMC.GEM_SYSTEM",
        "GEM_AMC.GEM_TESTS",
        "GEM_AMC.DAQ"
        "GEM_AMC.OH_LINKS.CTRL",
        "GEM_AMC.SLOW_CONTROL",
        "GEM_AMC.GLIB_SYSTEM",
        ]

    name = node.name
    if baseName is not None:
        name = name.replace(baseName + ".", "")

    if (num_of_oh == None and "%s.%s"%(baseName,name) in amcTopNodesToSkip):
        # only for writing the AMC specific file
        print('Not writing node "%s" to AMC uHAL address table file'%(name))
        return

    if num_of_oh in range(0,12):
        # only for writing the OH specific file
        if "%s.%s"%(baseName,name) in ohTopNodesToSkip:
            print('Not writing node "%s" to OH uHAL address table file'%(name))
            return
        if name in ["OH%d"%(oh) for oh in range(0,12) if oh != num_of_oh]:
            print('Not writing node "%s" to OH%d uHAL address table file'%(name,num_of_oh))
            return
    for i in range(level):
        file.write('  ')
        pass

    file.write('<node id="%s" ' % name)
    if node.address is not None:
        if baseName is None and level == 1:
            file.write('address="%s" ' % hex((node.address - baseAddress) + addrOffset))
        else:
            file.write('address="%s" ' % hex(node.address - baseAddress))
    if node.permission is not None:
        file.write('permission="%s" ' % node.permission)
    if node.mask is not None:
        file.write('mask="%s"' % hex(node.mask))
    if node.mode is not None:
        file.write('mode="%s"' % node.mode)

    if len(node.children) > 0:
        file.write('>\n')
        for child in node.children:
            printNodeToUHALFile(child, file, level + 1, node.address, node.name, addrOffset, num_of_oh)
        for i in range(level):
            file.write('  ')
        file.write('</node>\n')
    else:
        file.write('/>\n')

# prints out bash script to read registers matching an expression
def writeRegReadBashScript(modules, filename):
    print('Writing CTP7 reg read bash script')

    f = io.open(filename, 'w', encoding="utf-8")

    f.write('#!/bin/sh\n\n')
    f.write('REQUEST=$1\n\n')
    f.write('set -- ')

    for module in modules:
        for reg in module.regs:
            if 'r' in reg.permission:
                if reg.mask == 0xffffffff:
                    f.write('\\\n    "' + reg.name + ":`mpeek " + hex(AXI_IPB_BASE_ADDRESS + ((module.baseAddress + reg.address) << 2)) + "`\"")
#                    f.write('\\\n    "' + reg.name + ":`echo " + hex(AXI_IPB_BASE_ADDRESS + ((module.baseAddress + reg.address) << 2)) + "`\"")
                else:
                    f.write('\\\n    "' + reg.name + ":$(( (`mpeek " + hex(AXI_IPB_BASE_ADDRESS + ((module.baseAddress + reg.address) << 2)) + "` & " + hexPadded32(reg.mask) + ") >> " + str(reg.lsb) + " ))\"")
#                    f.write('\\\n    "' + reg.name + ":`echo " + hex(AXI_IPB_BASE_ADDRESS + ((module.baseAddress + reg.address) << 2)) + "`\"")

    f.write('\n\n')
    f.write('for reg; do\n')
    f.write('  KEY=${reg%%:*}\n')
    f.write('  case $KEY in\n')
    f.write("     *$REQUEST*) printf '%s            = 0x%x\\n' $KEY ${reg#*:};;\n")
    f.write('  esac\n')
    f.write('done\n')
    f.close()

# returns the number of required 32 bit registers for this module -- basically it counts the number of registers with different addresses
def getNumRequiredRegs32(module):
    totalRegs32 = 0
    if len(module.regs) > 0:
        totalRegs32 = 1
        lastAddress = module.regs[0].address
        for reg in module.regs:
            if reg.address != lastAddress:
                totalRegs32 += 1
                lastAddress = reg.address
    return totalRegs32

def hex(number):
    if number is None:
        return 'None'
    else:
        return "{0:#0x}".format(number)

def hexPadded32(number):
    if number is None:
        return 'None'
    else:
        return "{0:#0{1}x}".format(number, 10)

def binaryPadded32(number):
    if number is None:
        return 'None'
    else:
        return "{0:#0{1}b}".format(number, 34)

def vhdlHexPadded(number, numBits):
    if number is None:
        return 'None'
    else:
        hex32 = hexPadded32(number)
        binary32 = binaryPadded32(number)

        ret = ''

        # if the number is not aligned with hex nibbles, add  some binary in front
        numSingleBits = (numBits % 4)
        if (numSingleBits != 0):
            ret += "'" if numSingleBits == 1 else '"'
            # go back from the MSB down to the boundary of the most significant nibble
            for i in range(numBits, numBits // 4 * 4, -1):
                ret += binary32[i *  -1]
            ret += "'" if numSingleBits == 1 else '"'


        # add the right amount of hex characters

        if numBits // 4 > 0:
            if (numSingleBits != 0):
                ret += ' & '
            ret += 'x"'
            for i in range(numBits // 4, 0, -1):
                ret += hex32[i * -1]
            ret += '"'
        return ret


def parseInt(string):
    if string is None:
        return None
    elif string.startswith('0x'):
        return int(string, 16)
    elif string.startswith('0b'):
        return int(string, 2)
    else:
        return int(string)

def getLowHighFromBitmask(bitmask):
    binary32 = binaryPadded32(bitmask)
    lsb = -1
    msb = -1
    rangeDone = False
    for i in range(1, 33):
        if binary32[i * -1] == '1':
            if rangeDone == True:
                raise ValueError('Non-continuous bitmasks are not supported: %s' % hexPadded32(bitmask))
            if lsb == -1:
                lsb = i - 1
            msb = i - 1
        if lsb != -1 and binary32[i * -1] == '0':
            if rangeDone == False:
                rangeDone = True
    return msb, lsb

def substituteVars(string, vars):
    if string is None:
        return string
    ret = string
    for varKey in vars.keys():
        ret = ret.replace('${' + varKey + '}', str(vars[varKey]))
    return ret

if __name__ == '__main__':
    if sys.version_info[0] >= 3:
        raise Exception("Python 2 required.")
    main()
