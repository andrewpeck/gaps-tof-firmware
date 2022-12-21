#!/usr/bin/env python3
import os
import random
import pytest

import cocotb
from cocotb_test.simulator import run
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def clk_gen(signal, period, phase):

    # pre-construct triggers for performance
    high_time = Timer(period/2.0, units="ns")
    low_time = Timer(period/2.0, units="ns")
    await Timer(phase/360.0 * period, units="ns")
    while True:
        signal.value = 1
        await high_time
        signal.value = 0
        await low_time

def print_errs(dut):
    print(f" > e01 = {dut.e01.value}")
    print(f" > e12 = {dut.e12.value}")
    print(f" > e23 = {dut.e23.value}")
    print(f" > e30 = {dut.e30.value}")

@cocotb.test()
async def oversample(dut):
    """Test for priority encoder with randomized data on all inputs"""

    PERIOD=360

    cocotb.fork(clk_gen(dut.clk, PERIOD, 0))
    cocotb.fork(clk_gen(dut.clk90, PERIOD, 90))

    dut.data_i.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # sel0 =   0 degree
    # sel1 =  90 degree
    # sel2 = 180 degree
    # sel3 = 270 degree

    for i in range(100):

        phase = ((i * 5) % 720)

        # give it a few cycles to lock
        for j in range(10):

            for _ in range(16):
                await RisingEdge(dut.clk)

            if (phase > 90):
                await Timer(phase * PERIOD / 360, units="ns")

            dut.data_i.value=1
            await Timer(PERIOD, units="ns")
            tstart = float(str(get_sim_time('ns')))
            dut.data_i.value=0
            await RisingEdge(dut.clk)

        await RisingEdge(dut.data_o)
        print(get_sim_time('ns'))
        tend = float(str(get_sim_time('ns')))
        print("phase=%4.1f" % (phase))
        print(" > sel=%d" % dut.sel.value)
        print(" > data_o=%d" % dut.data_o.value)
        print(" > latency=%f" % ((tend-tstart)/PERIOD))

        # for select in (1,2,3,4):

        #     min = select*90 - 45
        #     max = select*90 + 45

        #     if (phase > min and phase < max):
        #         assert int(dut.sel.value) != select
                #assert int(dut.sel.value) != select + 2

        if phase < 15 :
            assert dut.sel.value != 0, print_errs(dut)
        if phase > 75 and phase < 105:
            assert dut.sel.value != 1, print_errs(dut)
        if phase > 165 and phase < 195:
            assert dut.sel.value != 2, print_errs(dut)
        if phase > 255 and phase < 285:
            assert dut.sel.value != 3, print_errs(dut)

        await RisingEdge(dut.clk)

def test_oversample():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'src'))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, f"oversample_iddr.vhd"),
    ]

    os.environ["SIM"] = "ghdl"

    run(
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="oversample",
        toplevel_lang="vhdl",
        gui=0
    )


if __name__ == "__main__":
    test_oversample()
