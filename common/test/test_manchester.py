#!/usr/bin/env python3
import os
import random
import pytest

import cocotb
from cocotb_test.simulator import run
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def mon_output(dut):
    ""
    await RisingEdge(dut.clk)  # Synchronize with the clock
    await RisingEdge(dut.clk)  # Synchronize with the clock
    await RisingEdge(dut.clk)  # Synchronize with the clock
    while (True):
        await RisingEdge(dut.clk)  # Synchronize with the clock
        # if (dut.dav.value==1):
        print("%d %d" % (dut.dout.value, dut.dav.value))

@cocotb.test()
async def random_clusters(dut):
    """Test for priority encoder with randomized data on all inputs"""

    cocotb.fork(Clock(dut.clk8x,  10, units="ns").start())  # Create a clock
    cocotb.fork(Clock(dut.clk,    80, units="ns").start())  # Create a clock
    cocotb.fork(mon_output(dut))

    dut.din.value = 0

    for _ in range(1000):

        for _ in range (8):
            await RisingEdge(dut.clk)

        dut.din.value = not dut.din.value

def test_manchester_decoder():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'src'))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(rtl_dir, f"manchester_encoder.vhd"),
        os.path.join(rtl_dir, f"manchester_decoder.vhd"),
        os.path.join(rtl_dir, f"../test/manchester_loop.vhd"),
    ]

    os.environ["SIM"] = "questa"

    run(
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="manchester_loop",
        toplevel_lang="vhdl",
        gui=1
    )


if __name__ == "__main__":
    test_manchester_decoder()
