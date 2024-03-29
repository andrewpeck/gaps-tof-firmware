
# https://numato.com/docs/callisto-kintex-7-usb-3-1-fpga-module/
# https://drive.google.com/drive/folders/19IckvaclJu1OXXpRnZHItwr0qBm4Qy50

set CCB_PIN_P1_A \
    [dict create \
         "A1" "EXT_VCC" \
         "A2" "GND" \
         "A3" "GND" \
         "A4" "J21" \
         "A5" "GND" \
         "A6" "G24" \
         "A7" "GND" \
         "A8" "D26" \
         "A9" "GND" \
         "A10" "D21" \
         "A11" "GND" \
         "A12" "K15" \
         "A13" "GND" \
         "A14" "B17" \
         "A15" "GND" \
         "A16" "G15" \
         "A17" "GND" \
         "A18" "E15" \
         "A19" "GND" \
         "A20" "H17" \
         "A21" "GND" \
         "A22" "H19" \
         "A23" "GND" \
         "A24" "K16" \
         "A25" "GND" \
         "A26" "B14" \
         "A27" "GND" \
         "A28" "A13" \
         "A29" "GND" \
         "A30" "B12" \
         "A31" "GND" \
         "A32" "A9" \
         "A33" "GND" \
         "A34" "C12" \
         "A35" "GND" \
         "A36" "E10" \
         "A37" "GND" \
         "A38" "NC" \
         "A39" "GND" \
         "A40" "VADJ_B12" \
        ]

set CCB_PIN_P1_B \
    [dict create \
         "B1" "EXT_VCC" \
         "B2" "GND" \
         "B3" "K23" \
         "B4" "H22" \
         "B5" "F25" \
         "B6" "F24" \
         "B7" "G22" \
         "B8" "C26" \
         "B9" "D23" \
         "B10" "C22" \
         "B11" "C21" \
         "B12" "M16" \
         "B13" "C16" \
         "B14" "A17" \
         "B15" "H16" \
         "B16" "F15" \
         "B17" "D15" \
         "B18" "E16" \
         "B19" "G17" \
         "B20" "H18" \
         "B21" "D19" \
         "B22" "G20" \
         "B23" "K20" \
         "B24" "K17" \
         "B25" "J8" \
         "B26" "A14" \
         "B27" "C14" \
         "B28" "A12" \
         "B29" "D14" \
         "B30" "B11" \
         "B31" "B10" \
         "B32" "A8" \
         "B33" "C9" \
         "B34" "C11" \
         "B35" "D9" \
         "B36" "D10" \
         "B37" "F9" \
         "B38" "NC" \
         "B39" "GND" \
         "B40" "VADJ_B15" \
        ]

set CCB_PIN_P1_C \
    [dict create \
         "C1" "EXT_VCC" \
         "C2" "GND" \
         "C3" "J23" \
         "C4" "GND" \
         "C5" "E26" \
         "C6" "GND" \
         "C7" "F23" \
         "C8" "GND" \
         "C9" "D24" \
         "C10" "GND" \
         "C11" "B21" \
         "C12" "GND" \
         "C13" "B16" \
         "C14" "GND" \
         "C15" "G16" \
         "C16" "GND" \
         "C17" "D16" \
         "C18" "GND" \
         "C19" "F18" \
         "C20" "GND" \
         "C21" "D20" \
         "C22" "GND" \
         "C23" "J20" \
         "C24" "GND" \
         "C25" "J14" \
         "C26" "GND" \
         "C27" "C13" \
         "C28" "GND" \
         "C29" "D13" \
         "C30" "GND" \
         "C31" "A10" \
         "C32" "GND" \
         "C33" "B9" \
         "C34" "GND" \
         "C35" "D8" \
         "C36" "GND" \
         "C37" "F8" \
         "C38" "GND" \
         "C39" "GND" \
         "C40" "VADJ_B16" \
        ]

set CCB_PIN_P1_D \
    [dict create \
         "D1" "EXT_VCC" \
         "D2" "GND" \
         "D3" "GND" \
         "D4" "L22" \
         "D5" "GND" \
         "D6" "J26" \
         "D7" "GND" \
         "D8" "H21" \
         "D9" "GND" \
         "D10" "E21" \
         "D11" "GND" \
         "D12" "B20" \
         "D13" "GND" \
         "D14" "C19" \
         "D15" "GND" \
         "D16" "J15" \
         "D17" "GND" \
         "D18" "F17" \
         "D19" "GND" \
         "D20" "G19" \
         "D21" "GND" \
         "D22" "J18" \
         "D23" "GND" \
         "D24" "L17" \
         "D25" "GND" \
         "D26" "F14" \
         "D27" "GND" \
         "D28" "E13" \
         "D29" "GND" \
         "D30" "E11" \
         "D31" "GND" \
         "D32" "H9" \
         "D33" "GND" \
         "D34" "J13" \
         "D35" "GND" \
         "D36" "J11" \
         "D37" "GND" \
         "D38" "NC" \
         "D39" "GND" \
         "D40" "VADJ_B32" \
        ]

set CCB_PIN_P1_E \
    [dict create \
         "E1" "EXT_VCC" \
         "E2" "GND" \
         "E3" "J24" \
         "E4" "K22" \
         "E5" "H23" \
         "E6" "H26" \
         "E7" "G25" \
         "E8" "G21" \
         "E9" "E25" \
         "E10" "E22" \
         "E11" "A23" \
         "E12" "A20" \
         "E13" "C17" \
         "E14" "B19" \
         "E15" "A18" \
         "E16" "J16" \
         "E17" "E18" \
         "E18" "E17" \
         "E19" "F19" \
         "E20" "F20" \
         "E21" "L19" \
         "E22" "J19" \
         "E23" "M17" \
         "E24" "K18" \
         "E25" "B15" \
         "E26" "F13" \
         "E27" "G12" \
         "E28" "E12" \
         "E29" "G11" \
         "E30" "D11" \
         "E31" "G10" \
         "E32" "H8" \
         "E33" "H14" \
         "E34" "H13" \
         "E35" "H12" \
         "E36" "J10" \
         "E37" "NC" \
         "E38" "NC" \
         "E39" "GND" \
         "E40" "VBATT" \
        ]

set CCB_PIN_P1_F \
    [dict create \
         "F1" "EXT_VCC" \
         "F2" "GND" \
         "F3" "J25" \
         "F4" "GND" \
         "F5" "H24" \
         "F6" "GND" \
         "F7" "G26" \
         "F8" "GND" \
         "F9" "D25" \
         "F10" "GND" \
         "F11" "A24" \
         "F12" "GND" \
         "F13" "C18" \
         "F14" "GND" \
         "F15" "A19" \
         "F16" "GND" \
         "F17" "D18" \
         "F18" "GND" \
         "F19" "E20" \
         "F20" "GND" \
         "F21" "L20" \
         "F22" "GND" \
         "F23" "L18" \
         "F24" "GND" \
         "F25" "A15" \
         "F26" "GND" \
         "F27" "F12" \
         "F28" "GND" \
         "F29" "F10" \
         "F30" "GND" \
         "F31" "G9" \
         "F32" "GND" \
         "F33" "G14" \
         "F34" "GND" \
         "F35" "H11" \
         "F36" "GND" \
         "F37" "NC" \
         "F38" "GND" \
         "F39" "GND" \
        ]

set CCB_PIN_P2_A \
    [dict create \
         "A1" "U24" \
         "A2" "GND" \
         "A3" "U26" \
         "A4" "GND" \
         "A5" "W23" \
         "A6" "GND" \
         "A7" "Y23" \
         "A8" "GND" \
         "A9" "AD23" \
         "A10" "GND" \
         "A11" "AF24" \
         "A12" "GND" \
         "A13" "AE22" \
         "A14" "GND" \
         "A15" "AF14" \
         "A16" "GND" \
         "A17" "AF19" \
         "A18" "GND" \
         "A19" "AC14" \
         "A20" "GND" \
         "A21" "AD20" \
         "A22" "GND" \
         "A23" "Y17" \
         "A24" "GND" \
         "A25" "V18" \
         "A26" "GND" \
         "A27" "AA8" \
         "A28" "GND" \
         "A29" "AC9" \
         "A30" "GND" \
         "A31" "AA13" \
         "A32" "GND" \
         "A33" "AE12" \
         "A34" "GND" \
         "A35" "N12" \
         "A36" "NC" \
         "A37" "B22" \
         "A38" "VCC3V3" \
         "A39" "GND" \
         "A40" "VCC3V3" \
        ]

set CCB_PIN_P2_B \
    [dict create \
         "B1" "U25" \
         "B2" "U22" \
         "B3" "V26" \
         "B4" "W25" \
         "B5" "W24" \
         "B6" "AB26" \
         "B7" "AA24" \
         "B8" "Y22" \
         "B9" "AD24" \
         "B10" "AB22" \
         "B11" "AF25" \
         "B12" "AD26" \
         "B13" "AF22" \
         "B14" "AE17" \
         "B15" "AF15" \
         "B16" "AE18" \
         "B17" "AF20" \
         "B18" "AD16" \
         "B19" "AD14" \
         "B20" "Y15" \
         "B21" "AE20" \
         "B22" "AA19" \
         "B23" "Y18" \
         "B24" "V16" \
         "B25" "V19" \
         "B26" "AE7" \
         "B27" "AA7" \
         "B28" "AC8" \
         "B29" "AD9" \
         "B30" "AB11" \
         "B31" "AA12" \
         "B32" "AC13" \
         "B33" "AF12" \
         "B34" "AE8" \
         "B35" "P11" \
         "B36" "J7" \
         "B37" "C8" \
         "B38" "L8" \
         "B39" "GND" \
         "B40" "VCC3V3" \
        ]

set CCB_PIN_P2_C \
    [dict create \
         "C1" "GND" \
         "C2" "V22" \
         "C3" "GND" \
         "C4" "W26" \
         "C5" "GND" \
         "C6" "AC26" \
         "C7" "GND" \
         "C8" "AA22" \
         "C9" "GND" \
         "C10" "AC22" \
         "C11" "GND" \
         "C12" "AE26" \
         "C13" "GND" \
         "C14" "AF17" \
         "C15" "GND" \
         "C16" "AF18" \
         "C17" "GND" \
         "C18" "AE16" \
         "C19" "GND" \
         "C20" "Y16" \
         "C21" "GND" \
         "C22" "AA20" \
         "C23" "GND" \
         "C24" "V17" \
         "C25" "GND" \
         "C26" "AF7" \
         "C27" "GND" \
         "C28" "AD8" \
         "C29" "GND" \
         "C30" "AC11" \
         "C31" "GND" \
         "C32" "AD13" \
         "C33" "GND" \
         "C34" "AF8" \
         "C35" "GND" \
         "C36" "B24" \
         "C37" "A25" \
         "C38" "N8" \
         "C39" "GND" \
         "C40" "VCC3V3" \
        ]

set CCB_PIN_P2_D \
    [dict create \
         "D1" "U21" \
         "D2" "GND" \
         "D3" "V21" \
         "D4" "GND" \
         "D5" "Y25" \
         "D6" "GND" \
         "D7" "AC23" \
         "D8" "GND" \
         "D9" "AB21" \
         "D10" "GND" \
         "D11" "AE23" \
         "D12" "GND" \
         "D13" "V13" \
         "D14" "GND" \
         "D15" "AD15" \
         "D16" "GND" \
         "D17" "AA14" \
         "D18" "GND" \
         "D19" "AB14" \
         "D20" "GND" \
         "D21" "AC19" \
         "D22" "GND" \
         "D23" "W18" \
         "D24" "GND" \
         "D25" "V14" \
         "D26" "GND" \
         "D27" "AB7" \
         "D28" "GND" \
         "D29" "AA10" \
         "D30" "GND" \
         "D31" "Y13" \
         "D32" "GND" \
         "D33" "AE13" \
         "D34" "GND" \
         "D35" "NC" \
         "D36" "A22" \
         "D37" "NC" \
         "D38" "R7" \
         "D39" "GND" \
         "D40" "VCC3V3" \
        ]

set CCB_PIN_P2_E \
    [dict create \
         "E1" "Y20" \
         "E2" "V23" \
         "E3" "W21" \
         "E4" "AA25" \
         "E5" "Y26" \
         "E6" "AA23" \
         "E7" "AC24" \
         "E8" "W20" \
         "E9" "AC21" \
         "E10" "AD21" \
         "E11" "AF23" \
         "E12" "AD25" \
         "E13" "W13" \
         "E14" "AA17" \
         "E15" "AE15" \
         "E16" "AB16" \
         "E17" "AA15" \
         "E18" "AC18" \
         "E19" "AB15" \
         "E20" "AB17" \
         "E21" "AD19" \
         "E22" "AB19" \
         "E23" "W19" \
         "E24" "W15" \
         "E25" "W14" \
         "E26" "U9" \
         "E27" "AC7" \
         "E28" "AA9" \
         "E29" "AB10" \
         "E30" "AB12" \
         "E31" "Y12" \
         "E32" "AD10" \
         "E33" "AF13" \
         "E34" "AF10" \
         "E35" "NC" \
         "E36" "C23" \
         "E37" "GND" \
         "E38" "R6" \
         "E39" "GND" \
         "E40" "VCC3V3" \
        ]

set CCB_PIN_P2_F \
    [dict create \
         "F1" "GND" \
         "F2" "V24" \
         "F3" "GND" \
         "F4" "AB25" \
         "F5" "GND" \
         "F6" "AB24" \
         "F7" "GND" \
         "F8" "Y21" \
         "F9" "GND" \
         "F10" "AE21" \
         "F11" "GND" \
         "F12" "AE25" \
         "F13" "GND" \
         "F14" "AA18" \
         "F15" "GND" \
         "F16" "AC16" \
         "F17" "GND" \
         "F18" "AD18" \
         "F19" "GND" \
         "F20" "AC17" \
         "F21" "GND" \
         "F22" "AB20" \
         "F23" "GND" \
         "F24" "W16" \
         "F25" "GND" \
         "F26" "V12" \
         "F27" "GND" \
         "F28" "AB9" \
         "F29" "GND" \
         "F30" "AC12" \
         "F31" "GND" \
         "F32" "AE10" \
         "F33" "GND" \
         "F34" "AF9" \
         "F35" "GND" \
         "F36" "G7" \
         "F37" "P6" \
         "F38" "GND" \
         "F39" "GND" \
         "F40" "VCC3V3" \
        ]


# call e.g. with
#
#     get_fpga_pin_from_header_pin P1 F39
#
proc get_fpga_pin_from_header_pin {p12 pin} {
    set row [string toupper [string range $pin 0 0]]
    set header [string toupper $p12]
    set lut_name ::CCB_PIN_${header}_${row}
    # puts $p12
    # puts $pin
    # puts $lut_name
    # puts [set $lut_name]
    return [dict get [set $lut_name] $pin]
}
