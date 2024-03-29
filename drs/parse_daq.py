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

        # print(data[START:END])
        # print(data[START:END].tobytes())
        # print(type((data[START:END])))
        #
        # print(self.data)
        # print(len(self.data))
        # print(type(self.data))

        crc = libscrc.crc32(self.data)
        # print("My:")
        # print(self.data)
        # print(type(self.data))
        # print("Fake:")
        # print(np.arange(0,1024,dtype='<u2'))
        # print(type(np.arange(0,1024,dtype='<u2')))
        #hex(libscrc.crc32(np.arange(0,1024,dtype='<u2')))
        print (self.data)

        if crc != self.crc:
            print("CH%d CRC FAIL calc=0x%08X, read=0x%08X" % (self.channel, crc, self.crc))
            return 1
        else:
            print("CH%d CRC ok (0x%08X)" % (self.channel, crc))

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
    stop_cell = np.uint16(0)
    ch_mask = np.uint16(0)
    event_cnt = np.uint32(0)
    dtap0 = np.uint16(0)
    dtap1 = np.uint16(0)
    timestamp = np.uint64(0)
    crc = np.uint32(0)

    waveforms = []

    def count_channels(self):
        count = 0
        for i in range(16):
            count += (self.ch_mask >> i) & 0x1
        if (self.ch_mask & 0xff):
            count += 1
        if (self.ch_mask & 0xff00):
            count += 1
        self.channels = count

    def get_channel_id(self, index):
        "Using the channel mask and a channel count index, return the channel id"
        cnt = 0
        for i in range(16):
            if i > 7 and (0xff & self.ch_mask):
                return 8

            if 0x1 & (self.ch_mask >> i):
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
        ret += ("DTAP0     : 0x%0*X\n" % (4, self.dtap0))
        ret += ("DTAP1     : 0x%0*X\n" % (4, self.dtap1))
        ret += ("TIMESTAMP : 0x%0*X\n" % (12, self.timestamp))
        ret += ("STOP_CELL : 0x%0*X\n" % (2, self.stop_cell))
        ret += ("CRC       : 0x%0*X\n" % (2, self.crc))
        ret += ("TRAILER   : 0x%0*X\n" % (2, self.trailer))
        return ret

def read_packet (data, drs_truth, start=0,  verbose=False):

    drs = DAQReadout()

    data = data[start:]

    drs.header = data[0]
    drs.status = data[1]
    drs.length = data[2]
    drs.roi_size = data[3]  # daq report counts from zero, we count from 1

    reverse_words = 1

    dna = data[4:8]

    if (reverse_words):
        dna = dna[::-1]
    drs.dna = int.from_bytes(dna, byteorder="little")

    drs.githash = data[8]
    drs.board_id = data[9]
    drs.ch_mask = data[10]
    drs.count_channels()

    event_cnt = data[11:13]
    if (reverse_words):
        event_cnt = event_cnt[::-1]

    drs.event_cnt = int.from_bytes(event_cnt, byteorder="little")

    drs.dtap0 = data[13]
    drs.dtap1 = data[14]

    drs.timestamp = int.from_bytes(data[15:18], byteorder="little")

    timestamp = data[15:18]
    if (reverse_words):
        timestamp = timestamp[::-1]

    drs.timestamp = int.from_bytes(timestamp, byteorder="little")

    NUM_HEADERS = 19

    drs.waveforms.clear()

    #print (drs.channels)
    for i in range(drs.channels):

        START = NUM_HEADERS+i*(drs.roi_size+1+3)
        END = NUM_HEADERS+i*(drs.roi_size+1+3) + drs.roi_size+1

        start = data[START]
        #end = data[END-1]
        crc = data[END:END+2]
        #ch = data[START-1]
        #data" + str(data[START:END]))

        if (reverse_words):
            crc = crc[::-1]

        if (verbose):
            print("start=%d, data=0x%02X" %(START, data[START]))
            print("end=%d, data=0x%02X" % (END, data[END-1]))
            print("data" + str(data[START:END]))
            print("crc" + str(data[END:END+2]))
            print("ch" + str(data[START-1]))
            print("")

        #print(data[START:END])
        # print(data[START:END].tobytes())
        # print(type((data[START:END])))

        channel = data[START-1]

        crc = data[END:END+2]
        if (reverse_words):
            crc = crc[::-1]

        crc = int.from_bytes(crc, byteorder="little")

        drs.waveforms.append(DRSWaveform(data[START:END], crc, channel))

        drs.waveforms[i].check_crc()

        if (verbose):
            print(drs.waveforms[i])

    drs.stop_cell = data[END+2]

    drs.trailer = data[drs.length-1]

    print(drs)

    crc = data[drs.length-3:drs.length-1]
    if (reverse_words):
        crc = crc[::-1]
    drs.crc = int.from_bytes(crc, byteorder="little")

    packet_crc = libscrc.crc32(data[0:drs.length-3])  # subtract trailer + crc

    print("Packet CRC calc=%08X data=%08X" % (packet_crc, drs.crc))
    if packet_crc != drs.crc:
        print("Packet  CRC fail")

    assert drs_truth.status    == drs.status
    assert drs_truth.dna       == drs.dna
    assert drs_truth.githash   == drs.githash, "read=" + hex(drs.githash)
    assert drs_truth.board_id  == drs.board_id
    assert drs_truth.ch_mask   == drs.ch_mask
    assert drs_truth.event_cnt == drs.event_cnt
    assert drs_truth.timestamp == drs.timestamp
    assert drs_truth.roi_size  == drs.roi_size
    assert drs_truth.stop_cell == drs.stop_cell, "read=" + hex(drs.stop_cell)

    assert drs.header == 0xAAAA
    assert drs.trailer == 0x5555

    print("--------------------")
    print("")

if __name__ == "__main__":

    # a = np.fromfile("packet_3.bin", dtype='<u2', count=-1, sep='')
    # i = 0
    # for byte in a:
    #     if (i%2==1):
    #         print("0x%04X" % byte)
    #     i=i+1

    a = np.fromfile("daq_packet.dat", dtype='<u2', count=-1, sep='')
    print(a)
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
        drs.stop_cell = 0x7777
        drs.event_cnt = 0x76543210
        drs.timestamp = 0xba9876543210
        drs.roi_size = 0x3ff

        read_packet(data=a, drs_truth=drs, start=0, verbose=False)

        drs = DAQReadout()

        drs.status = 0x0000
        drs.dna = 0xfedcba9876543210
        drs.githash = 0x0abc
        drs.board_id = 0x7700
        drs.ch_mask = 0xff
        drs.stop_cell = 0x2aa
        drs.event_cnt = 0x99999999
        drs.timestamp = 0x444444444444
        drs.roi_size = 0x3ff

        read_packet(data=a, drs_truth=drs, start=9280, verbose=False)

        drs = DAQReadout()

        drs.status = 0x0000
        drs.dna = 0x6c886c886c886c88
        drs.githash = 0x06c8
        drs.board_id = 0x0000
        drs.ch_mask = 0xff
        drs.stop_cell = 0x2aa
        drs.event_cnt = 0xffeeddcc
        drs.timestamp = 0x0123456789ab
        drs.roi_size = 1023

        read_packet(data=a, drs_truth=drs, start=18560, verbose=False)
