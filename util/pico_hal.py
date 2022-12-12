#!/usr/bin/env python3
import socket
import random
from enum import Enum

PACKET_ID = 0
IPADDR = "10.97.108.15"
PORT = 50001

# Create a UDP socket and bind the socket to the port
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
target_address = ("", 0)

READ = 0
WRITE = 1
READ_NON_INCR = 2
WRITE_NON_INCR = 3
RMW = 4

typedef = {
    READ: "READ",
    WRITE: "WRITE",
    READ_NON_INCR: "READ (non incremental)",
    WRITE_NON_INCR: "WRITE (non incremental)",
    RMW: "Read Modify Write",
}

# Recieve
def decode_ipbus(message, verbose=False):

    # Response
    ipbus_version = message[0] >> 4
    id = ((message[4] & 0xf) << 8) | message[5]
    size = message[6]
    type = (message[7] & 0xf0) >> 4
    info_code = message[7] & 0xf
    data = [None]*size

    # Read
    if type==READ or type==READ_NON_INCR:
        for i in range(size):
            data[i]=((message[8 + i * 4] << 24) | (message[9 + i * 4] << 16) | (message[10 + i * 4] << 8) | message[11 + i * 4])

    # Write
    if type==WRITE:
        data = [0]

    if (verbose):
        print("Decoding IPBus Packet:")
        print(f" > Msg = {message}")
        print(f" > IPBus version = {ipbus_version}")
        print(f" > ID = {id}")
        print(f" > Size = {size}")
        print(f" > Type = {type} %s" % typedef[type])
        print(f" > Info = {info_code}")
        print(f" > data = {data}")

    return (data)

def encode_ipbus(addr, packet_type, data):

    size = len(data)

    """Format a UDP packet from a byte array"""
    udp_data = [
        # Transaction Header
        0x20, # Protocol version & RSVD
        0x00, # Transaction ID (0 or bug)
        0x00, # Transaction ID (0 or bug)
        0xf0, # Packet order & packet_type
        # Packet Header
        (0x20 | ((PACKET_ID & 0xf00) >> 8)), # Protocol version & Packet ID MSB
        (PACKET_ID & 0xff), # Packet ID LSB,
        size, # Words
        (((packet_type & 0xf) << 4) | 0xf), # Packet_Type & Info code
        # Address
        ((addr & 0xff000000) >> 24),
        ((addr & 0x00ff0000) >> 16),
        ((addr & 0x0000ff00) >> 8),
        (addr & 0x000000ff),]

    if packet_type == WRITE or packet_type == WRITE_NON_INCR:
        for i in range(size):
            udp_data.append((data[i] & 0xff000000) >> 24)
            udp_data.append((data[i] & 0x00ff0000) >> 16)
            udp_data.append((data[i] & 0x0000ff00) >> 8)
            udp_data.append(data[i] & 0x000000ff)

    return bytes(udp_data)

def wReg(address, data, verify=False):
    s.sendto(encode_ipbus(addr=address, packet_type=WRITE, data=[data]), target_address)
    s.recvfrom(4096)
    rdback = rReg(address)
    if (verify and rdback != data):
        print("Error!")

def rReg(address):
    s.sendto(encode_ipbus(addr=address, packet_type=READ, data=[0x0]), target_address)
    data, address = s.recvfrom(4096)
    return decode_ipbus(data,False)[0]

c_addr = 0x1004
div_addr = 0x1005
ss_addr = 0x1006
d_addr = (0x1000, 0x1001, 0x1002, 0x1003)

def wSpiSS(ss):
    wReg(ss_addr, ss)

def wSpiWord(word):
    wReg(d_addr[0], word, verify=False)

def wSpiCtrl(char_len=None, go=None, rx_neg=None, tx_neg=None, lsb=None, ie=None, ass=None):

    reg = rReg(c_addr)

    if (char_len is not None):
        reg &= (0xffffffff ^ 0x7f)
        reg |= (0x7f & char_len)
    if (go is not None):
        reg &= (0xffffffff ^ 0x100)
        reg |= (0x1 & go) << 8
    if (rx_neg is not None):
        reg &= (0xffffffff ^ 0x200)
        reg |= (0x1 & rx_neg) << 9
    if (tx_neg is not None):
        reg &= (0xffffffff ^ 0x400)
        reg |= (0x1 & tx_neg) << 10
    if (lsb is not None):
        reg &= (0xffffffff ^ 0x800)
        reg |= (0x1 & lsb) << 11
    if (ie is not None):
        reg &= (0xffffffff ^ 0x1000)
        reg |= (0x1 & ie) << 12
    if (ass is not None):
        reg &= (0xffffffff ^ 0x2000)
        reg |= (0x1 & ass) << 13

    wReg(c_addr, reg, verify=False)

def rSpi(channel=0, adc=0):
    wReg(div_addr, 127, verify=False)
    # 0x18 start bit + for single ended
    wSpiWord((0x18 | (0x7 & channel)) << 16)
    wSpiCtrl(go=0)
    wSpiCtrl(ass=1, tx_neg=1, char_len=24)
    wSpiCtrl(go=1)
    wSpiCtrl(go=0)
    wSpiSS(0x1 << adc)
    return rReg(d_addr[0])

def read_adc(adc, ch, shift=2):
    data = rSpi(ch, adc)
    data = (data >> shift) & 0xfff
    return data

def read_adcs():

    from tabulate import tabulate

    channels = [
        {"function": "NC"           , "conversion": 1,   "unit": "V"},
        {"function": "DSI1 Current" , "conversion": 1,   "unit": "A"},
        {"function": "DSI2 Current" , "conversion": 1,   "unit": "A"},
        {"function": "DSI3 Current" , "conversion": 1,   "unit": "A"},
        {"function": "DSI4 Current" , "conversion": 1,   "unit": "A"},
        {"function": "DSI5 Current" , "conversion": 1,   "unit": "A"},
        {"function": "NC"           , "conversion": 1,   "unit": "V"},
        {"function": "CCB Current"  , "conversion": 1,   "unit": "A"},
        {"function": "12V Voltage"  , "conversion": 0.1, "unit": "V"},
        {"function": "3.3V Voltage" , "conversion": 0.5, "unit": "V"},
        {"function": "2.5V Voltage" , "conversion": 0.5, "unit": "V"},
        {"function": "Misc 0"       , "conversion": 1,   "unit": "V"},
        {"function": "Misc 1"       , "conversion": 1,   "unit": "V"},
        {"function": "Misc 2"       , "conversion": 1,   "unit": "V"},
        {"function": "Misc 3"       , "conversion": 1,   "unit": "V"},
        {"function": "NC"           , "conversion": 1,   "unit": "V"},]

    headers = ["Ch", "Reading", "Value", "Function"]
    table = []

    for adc in range(2):
        for channel in range(8):
            ichn = adc*8 + channel
            data = sum(read_adc(adc, channel) for _ in range(5)) / 5.0
            value = 2.5 * data / (2**12-1)

            table.append([ichn,
                        "0x%03X" % int(data),
                        "%4.2f %s" % (value / channels[ichn]["conversion"], channels[ichn]["unit"]),
                        channels[ichn]["function"],
                        ])

    print(tabulate(table, headers=headers,  tablefmt="simple_outline"))

    return([headers]+table)

def set_ucla_trigger(val):
    bit = 1
    if val:
        val = bit
    rd = rReg(0xb)
    wr = (rd & (0xffffffff ^ bit)) | val
    wReg(0xb, wr, verify=True)

def set_ssl_trigger(val):
    bit = 2
    if val:
        val = bit
    rd = rReg(0xb)
    wr = (rd & (0xffffffff ^ bit)) | val
    wReg(0xb, wr, verify=True)

def set_any_trigger(val):
    bit = 4
    if val:
        val = bit
    rd = rReg(0xb)
    wr = (rd & (0xffffffff ^ bit)) | val
    wReg(0xb, wr, verify=True)

def loopback(nreads=10000):
    print(" > Running loopback test")
    from tqdm import tqdm
    for i in tqdm(range(nreads), colour='green'):
        write = random.randint(0, 0xffffffff)
        wReg(0,write)
        read = rReg(0)
        assert write==read
        # if (i % 100 == 0):
        #     print(f"{i} reads, %f Mb" % ((i*32.0)/1000000.0))

if __name__ == '__main__':

    import argparse

    argParser = argparse.ArgumentParser(description = "Argument parser")

    argParser.add_argument('--ip',            action='store',      default=False, help="IP Address")
    argParser.add_argument('--ucla_trig_en',  action='store_true', default=False, help="Enable UCLA trigger")
    argParser.add_argument('--ssl_trig_en',   action='store_true', default=False, help="Enable SSL trigger")
    argParser.add_argument('--any_trig_en',   action='store_true', default=False, help="Enable ANY trigger")
    argParser.add_argument('--ucla_trig_dis', action='store_true', default=False, help="Disable UCLA trigger")
    argParser.add_argument('--ssl_trig_dis',  action='store_true', default=False, help="Disable SSL trigger")
    argParser.add_argument('--any_trig_dis',  action='store_true', default=False, help="Disable ANY trigger")
    argParser.add_argument('--read_adc',      action='store_true', default=False, help="Read ADCs")
    argParser.add_argument('--loopback',      action='store_true', default=False, help="Ethernet Loopback")

    args = argParser.parse_args()

    if args.ip:
        IPADDR = args.ip

    target_address = (IPADDR, PORT)

    if args.ucla_trig_en:
        set_ucla_trigger(1)
    if args.ssl_trig_en:
        set_ssl_trigger(1)
    if args.any_trig_en:
        set_any_trigger(1)
    if args.ucla_trig_dis:
        set_ucla_trigger(0)
    if args.ssl_trig_dis:
        set_ssl_trigger(0)
    if args.any_trig_dis:
        set_any_trigger(0)
    if args.read_adc:
        read_adcs()
    if args.loopback:
        loopback()
