#!/usr/bin/env python3
import numpy as np
import libscrc

class DRSWaveform():
    def __init__(self, array, crc, channel):
        self.data = array #np.zeros(size)
        self.crc = crc
        self.channel = channel

    def __str__(self):
        ret = ""
        ret += "Waveform : " + self.data.__str__() + "\n"
        ret += "CRC      : 0x%0*X" % (2, self.crc)
        return ret

    def check_crc(self):
        crc = libscrc.crc32(self.data)

        if crc != self.crc:
            print("CH%d CRC FAIL calc=0x%08X, read=0x%08X" % (self.channel, crc, self.crc))
            return 1

        return 0

class DAQReadout():
    header = np.uint16(0)
    trailer = np.uint16(0)
    status = np.uint16(0)
    dna = np.uint64(0)
    channels = np.uint16(0)
    roi_size = np.uint16(0)
    board_id = np.uint16(0)
    ch_mask = np.uint16(0)
    event_cnt = np.uint32(0)
    timestamp = np.uint64(0)
    crc = np.uint32(0)

    waveforms = []

    def count_channels(self):
        # NOTE: this needs to change if a single daq modules wants to support both drs chips
        if self.ch_mask == 0x00ff:
            self.channels = 9
        elif self.ch_mask == 0xff00:
            self.channels = 9
        else:
            count = 0
            for i in range(16):
                count += (self.ch_mask>>i)&0x1
            if count > 0:
                count += 1
            self.channels = count

    def get_channel_index(self, index):
        cnt = 0
        # NOTE: this needs to change if a single daq modules wants to support both drs chips
        if self.ch_mask == 0xFF:
            return index
        for i in range(16):
            if 0x1 & (self.ch_mask>> i):
                if cnt == index:
                    return i
                cnt += 1

    def __str__(self):
        ret = ""
        ret += ("HEADER    : 0x%0*X\n" % (2, self.header))
        ret += ("STATUS    : 0x%0*X\n" % (2, self.status))
        ret += ("LENGTH    : 0x%0*X\n" % (2, self.length))
        ret += ("ROI_SIZE  : %d\n"     % (self.roi_size))
        ret += ("DNA       : 0x%0*X\n" % (16, self.dna))
        ret += ("BOARD     : 0x%0*X\n" % (2, self.board_id))
        ret += ("MASK      : 0x%0*X\n" % (2, self.ch_mask))
        ret += ("NUM_CH    : %d\n"     % (self.channels))
        ret += ("EVENT_CNT : 0x%0*X\n" % (8, self.event_cnt))
        ret += ("TIMESTAMP : 0x%0*X\n" % (12, self.timestamp))
        ret += ("CRC       : 0x%0*X\n" % (2, self.crc))
        ret += ("TRAILER   : 0x%0*X\n" % (2, self.trailer))
        return ret

def read_packet (data, verbose=False):

    drs = DAQReadout()
    drs.header = data[0]
    drs.status = data[1]
    drs.length = data[2]
    drs.roi_size = data[3]+1 # daq report counts from zero, we count from 1
    drs.dna = int.from_bytes(data[4:8], byteorder="big")
    drs.board_id = data[8]
    drs.ch_mask = data[9]
    drs.count_channels()
    drs.event_cnt = int.from_bytes(data[10:12], byteorder="big")
    drs.timestamp = int.from_bytes(data[12:15], byteorder="big")

    for ch in range(drs.channels):


        START = 16+ch*(drs.roi_size+3)
        END = 16+ch*(drs.roi_size+3) + drs.roi_size

        drs.waveforms.append(DRSWaveform(data[START:END], \
                                    int.from_bytes(data[END:END+2], byteorder="big"), \
                                            data[START-1]))
                                    #drs.get_channel_index(ch)))

        drs.waveforms[ch].check_crc()

    drs.crc = int.from_bytes(data[drs.length-3:drs.length-1], byteorder="big")
    drs.trailer = data[drs.length-1]

    if (verbose):
        print(drs)

    packet_crc = libscrc.crc32(data[0:drs.length-3]) # subtract trailer + crc

    if packet_crc != drs.crc:
        print ("Packet  CRC fail")
        print ("calc=%08X data=%08X" % (packet_crc, drs.crc))

if __name__ == "__main__":
    a = np.fromfile("daq_packet.dat", dtype='>u2', count=-1, sep='', offset=0)
    np.set_printoptions(formatter={'int':hex})
    PROFILE=True
    if PROFILE:
        def loop_read(a):
            for i in range(100000):
                read_packet(a,False)

        import cProfile
        cProfile.run('loop_read(a)', "stats")
        import pstats
        p = pstats.Stats('stats')
        p.strip_dirs().sort_stats('time').print_stats(20)
        read_packet(a,True)
    else:
        read_packet(a,True)
