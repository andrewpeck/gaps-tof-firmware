#!/usr/bin/env python3
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run


async def init(dut):
    cocotb.start_soon(Clock(dut.clock, 10, units="ns").start())  # Create a clock
    dut.reset.value = 0
    dut.tiu_busy_i.value = 0
    dut.tiu_busy_ignore_i.value = 0
    dut.tiu_uart_i.value = 0
    dut.pre_trigger_i.value = 0
    dut.timestamp_i.value = 1
    dut.event_cnt_i.value = 0
    dut.tiu_busy_ignore_i.value = 0


async def idle(dut, nclks):
    for i in range(nclks):
        await RisingEdge(dut.clock)


async def reset(dut):
    # RESET
    dut.reset.value = 1
    await idle(dut, 10)
    dut.reset.value = 0
    await idle(dut, 2)


@cocotb.test()
async def tiu_test_busy_length(dut) -> None:
    "Test the busy length logic"
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_gps_rx(dut) -> None:
    "Send in a GPS serial word, make sure we receive it correctly."
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_timestamp(dut) -> None:
    "Make sure the latched timestamp is accurate."
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_stuck_logic(dut) -> None:
    "Make the TIU stuck, ensure that it is asserted"
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_busy(dut) -> None:
    "Generate a trigger and ack, make sure trigger_o restores within allotted time"
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_ack(dut) -> None:
    "Generate a trigger and ack, make sure trigger_o restores within allotted time"
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_serial_out(dut):
    """Init a trigger, make sure trigger_o is asserted"""
    await init(dut)
    await reset(dut)


@cocotb.test()
async def tiu_test_timeout(dut):
    """Generate a trigger but never acknowledge; make sure that the state machine does not lock up"""
    await init(dut)
    await reset(dut)

    await idle(dut, 10)

    # after reset, trigger should be 0
    assert dut.tiu_trigger_o.value == 0

    # assert the trigger
    # after a short timer it should be high
    dut.pre_trigger_i.value = 1
    await Timer(1)
    assert dut.tiu_trigger_o.value == 1
    await RisingEdge(dut.clock)

    # wait for the timeout
    await RisingEdge(dut.tiu_timeout_o)
    await idle(dut, 2)
    assert dut.tiu_trigger_o.value == 0


@cocotb.test()
async def tiu_test_trigger(dut):
    """Init a trigger, make sure trigger_o is asserted"""
    await init(dut)
    await reset(dut)

    await idle(dut, 10)

    # after reset, trigger should be 0
    assert dut.tiu_trigger_o.value == 0

    # assert the trigger
    # after a short timer it should be high
    dut.pre_trigger_i.value = 1
    await Timer(1)
    assert dut.tiu_trigger_o.value == 1

    # deassert the trigger input
    await RisingEdge(dut.clock)
    dut.pre_trigger_i.value = 0
    assert dut.tiu_trigger_o.value == 1
    await RisingEdge(dut.clock)

    # ACK; it should go low a few cycles later
    dut.tiu_busy_i.value = 1

    await idle(dut, 8)  # 8 cycles since it goes through a glitch filter
    assert dut.tiu_trigger_o.value == 0


def test_tiu():

    from cocotb.runner import get_runner

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, "../../../common/src/uart/tiny_uart_inp_filter.vhd"),
        os.path.join(tests_dir, "../../../common/src/uart/tiny_uart_baud_bit_gen.vhd"),
        os.path.join(tests_dir, "../../../common/src/uart/tiny_uart.vhd"),
        os.path.join(tests_dir, "../../../common/src/oneshot.vhd"),
        os.path.join(tests_dir, "../infra/components.vhd"),
        os.path.join(tests_dir, "tiu_tx.vhd"),
        os.path.join(tests_dir, "tiu_uart.vhd"),
        os.path.join(tests_dir, "tiu.vhd"),
    ]

    runner = get_runner('ghdl')
    toplevel = "tiu"
    build_args = ["--std=08"]
    test_args = ["--std=08"]
    plus_args = ["--wave=sim.ghw", "--ieee-asserts=disable"]

    runner.build(
        verilog_sources=[],
        vhdl_sources=vhdl_sources,
        hdl_toplevel=toplevel,
        parameters={'DEBUG': False},
        build_args=build_args,
        waves=1
    )

    runner.test(
        test_args=test_args,
        hdl_toplevel=toplevel,
        test_module=module,
        plusargs = plus_args,
        parameters={'DEBUG': False},
        waves=1
    )


if __name__ == "__main__":
    test_tiu()
