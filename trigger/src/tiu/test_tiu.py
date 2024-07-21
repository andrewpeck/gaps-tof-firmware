#!/usr/bin/env python3
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run


@cocotb.test()
async def tiu_test_comms(dut):
    """Test communication with the TIU"""

    cocotb.start_soon(Clock(dut.clock, 5, units="ns").start())  # Create a clock

    dut.reset.value = 0
    dut.tiu_busy_i.value = 0
    dut.tiu_gps_i.value = 0
    dut.pre_trigger_i.value = 0
    dut.tiu_emu_busy_cnt_i.value = 0
    dut.tiu_emulation_mode.value = 0
    dut.timestamp_i.value = 1
    dut.event_cnt_i.value = 0
    dut.tiu_busy_ignore_i.value = 0

    # RESET
    dut.reset.value = 1
    for i in range(10):
        await RisingEdge(dut.clock)
        dut.event_cnt_i.value += 1
    dut.reset.value = 0

    for _ in range(5):

        # TRIGGER
        await RisingEdge(dut.clock)
        dut.event_cnt_i.value += 1
        dut.pre_trigger_i.value = 1
        await RisingEdge(dut.clock)
        dut.event_cnt_i.value += 1
        dut.pre_trigger_i.value = 0

        #
        for i in range(10000):
            if i == 100:
                dut.tiu_busy_i.value = 1
            if i == 200:
                dut.tiu_busy_i.value = 0
            await RisingEdge(dut.clock)

        for i in range(10):
            await RisingEdge(dut.clock)


def test_tiu():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, f"../../../common/src/uart/tiny_uart_inp_filter.vhd"),
        os.path.join(tests_dir, f"../../../common/src/uart/tiny_uart_baud_bit_gen.vhd"),
        os.path.join(tests_dir, f"../../../common/src/uart/tiny_uart.vhd"),
        os.path.join(tests_dir, f"../infra/components.vhd"),
        os.path.join(tests_dir, f"tiu_tx.vhd"),
        os.path.join(tests_dir, f"tiu.vhd"),
    ]

    os.environ["SIM"] = "ghdl"

    run(
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="tiu",
        compile_args=["--std=08"],
        toplevel_lang="vhdl",
        gui=1,
        waves=1
    )


if __name__ == "__main__":
    test_tiu()
