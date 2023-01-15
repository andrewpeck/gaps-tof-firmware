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

@cocotb.test()
async def tiu_test_comms(dut):
    """Test for priority encoder with randomized data on all inputs"""

    PERIOD=36

    cocotb.fork(Clock(dut.clock,  36, units="ns").start())  # Create a clock

    dut.reset.value = 0
    dut.tiu_busy_i.value = 0
    dut.tiu_gps_i.value = 0
    dut.trigger_i.value = 0
    dut.tiu_emulation_mode.value = 1
    dut.timestamp_i.value = 0x12345678
    dut.event_cnt_i.value = 0xabcd0123

    # RESET
    dut.reset.value = 1
    for i in range(10):
        await RisingEdge(dut.clock)
    dut.reset.value = 0

    # TRIGGER
    await RisingEdge(dut.clock)
    dut.trigger_i.value = 1
    await RisingEdge(dut.clock)
    dut.trigger_i.value = 0

    #
    for i in range(10000):
        if i==100:
            dut.tiu_busy_i.value = 1
        if i==200:
            dut.tiu_busy_i.value = 0
        await RisingEdge(dut.clock)

    while True:
        await RisingEdge(dut.clock)

def test_tiu():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'src'))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, f"../../../common/src/uart/tiny_uart_inp_filter.vhd"),
        os.path.join(tests_dir, f"../../../common/src/uart/tiny_uart_baud_bit_gen.vhd"),
        os.path.join(tests_dir, f"../../../common/src/uart/tiny_uart.vhd"),
        os.path.join(tests_dir, f"tiu_tx.vhd"),
        os.path.join(tests_dir, f"tiu.vhd"),
    ]

    os.environ["SIM"] = "questa"

    run(
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="tiu",
        compile_args=["-2008"],
        toplevel_lang="vhdl",
        gui=1
    )

if __name__ == "__main__":
    test_tiu()
