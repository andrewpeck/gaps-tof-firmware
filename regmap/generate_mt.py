#!/usr/bin/env python3
import sys
import generate_registers as reg

CONFIG = {
    'TOP_NODE_NAME'                 : 'DRS',
    'ADDRESS_TABLE_TOP'             : '../mt_registers.xml',
    'CONSTANTS_FILE'                : '../trigger/src/registers.vhd',
    'DOC_FILE'                      : './mt_address_table.tex',
    'ORG_FILE'                      : './mt_address_table.org',
    'PACKAGE_FILE'                  : '../trigger/src/ipbus_pkg.vhd',
    'VHDL_REG_GENERATED_DISCLAIMER' : '(this section is generated by generate_registers.py -- do not edit)'
}

if __name__ == '__main__':
    reg.main(CONFIG)
