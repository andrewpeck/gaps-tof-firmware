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

        #print ("CRC=0x%08X" % crc)

        if crc != self.crc:
            print("CH%d CRC FAIL calc=0x%08X, read=0x%08X" % (self.channel, crc, self.crc))
            return 1

        return 0

class DAQReadout():

    header = np.uint16(0)
    trailer = np.uint16(0)
    status = np.uint16(0)
    dna = np.uint64(0)
    githash = np.uint16(0)
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
        ret += ("DNA       : 0x%0*X\n" % (4, self.dna))
        ret += ("GITHASH   : 0x%0*X\n" % (4, self.githash))
        ret += ("BOARD     : 0x%0*X\n" % (2, self.board_id))
        ret += ("MASK      : 0x%0*X\n" % (2, self.ch_mask))
        ret += ("NUM_CH    : %d\n"     % (self.channels))
        ret += ("EVENT_CNT : 0x%0*X\n" % (8, self.event_cnt))
        ret += ("TIMESTAMP : 0x%0*X\n" % (12, self.timestamp))
        ret += ("CRC       : 0x%0*X\n" % (2, self.crc))
        ret += ("TRAILER   : 0x%0*X\n" % (2, self.trailer))
        return ret

def read_packet (data, drs_truth, start=0,  verbose=False):

    drs = DAQReadout()

    data = data[start:]

    drs.header = data[0]
    drs.status = data[1]
    drs.length = data[2]
    drs.roi_size = data[3]+1 # daq report counts from zero, we count from 1
    drs.dna = int.from_bytes(data[4:8], byteorder="big")
    drs.githash = data[8]
    drs.board_id = data[9]
    drs.ch_mask = data[10]
    drs.count_channels()
    drs.event_cnt = int.from_bytes(data[11:13], byteorder="big")
    drs.timestamp = int.from_bytes(data[13:16], byteorder="big")

    for ch in range(drs.channels):

        START = 17+ch*(drs.roi_size+3)
        END = 17+ch*(drs.roi_size+3) + drs.roi_size

        if (verbose==True):
            print("start=%d, data=0x%02X" %(START, data[START]))
            print("end=%d, data=0x%02X" % (END, data[END-1]))
            print("data" + str(data[START:END]))
            print("crc" + str(data[END:END+2]))
            print("ch" + str(data[START-1]))
            print("")

        drs.waveforms.append(
            DRSWaveform(data[START:END],
                        int.from_bytes(data[END:END+2], byteorder="big"),
                        data[START-1]))

        drs.waveforms[ch].check_crc()

    drs.crc = int.from_bytes(data[drs.length-3:drs.length-1], byteorder="big")
    drs.trailer = data[drs.length-1]

    print(drs)

    packet_crc = libscrc.crc32(data[0:drs.length-3]) # subtract trailer + crc

    if packet_crc != drs.crc:
        print ("Packet  CRC fail")
        print ("calc=%08X data=%08X" % (packet_crc, drs.crc))

    assert drs_truth.status    == drs.status
    assert drs_truth.dna       == drs.dna
    assert drs_truth.githash   == drs.githash
    assert drs_truth.board_id  == drs.board_id
    assert drs_truth.ch_mask   == drs.ch_mask
    assert drs_truth.event_cnt == drs.event_cnt
    assert drs_truth.timestamp == drs.timestamp

    assert drs.header==0xAAAA
    assert drs.trailer==0x5555

if __name__ == "__main__":

    # a = np.fromfile("packet_3.bin", dtype='<u2', count=-1, sep='')
    # i = 0
    # for byte in a:
    #     if (i%2==1):
    #         print("0x%04X" % byte)
    #     i=i+1

    a = np.fromfile("daq_packet.dat", dtype='>u2', count=-1, sep='')

    np.set_printoptions(formatter={'int':hex})

    PROFILE = False

    if PROFILE:
        def loop_read(a):
            for i in range(100000):
                read_packet(a, False)

        import cProfile
        cProfile.run('loop_read(a)', "stats")
        import pstats
        p = pstats.Stats('stats')
        p.strip_dirs().sort_stats('time').print_stats(20)
        read_packet(a, True)
    else:

        drs = DAQReadout()

        drs.status = 0x9999
        drs.dna = 0xfedcba9876543210
        drs.githash = 0x3210
        drs.board_id = 0x4444
        drs.ch_mask = 0xff
        drs.event_cnt = 0x76543210
        drs.timestamp = 0xba9876543210

        read_packet(a, drs, 0, False)

        drs = DAQReadout()

        drs.status = 0x0000
        drs.dna = 0x6666666666666666
        drs.githash = 0xcccc
        drs.board_id = 0x7700
        drs.ch_mask = 0xf0
        drs.event_cnt = 0x99999999
        drs.timestamp = 0x444444444444

        read_packet(a, drs, 9264, False)
