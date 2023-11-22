#!/usr/bin/env python3
import os
import random

import cocotb
from cocotb_test.simulator import run
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# monitor that the trigger signal is always asserted when the event counter increments

# monitor that the event counter increments when the tirgger signal is asserted


async def monitor_trig_width(dut):
    "monitor that the trigger is never more than 1 clock long"
    await RisingEdge(dut.hits_i)
    while True:
        if dut.global_trigger_o == 1:
            await RisingEdge(dut.clk)
            assert dut.global_trigger_o == 0
        await RisingEdge(dut.clk)


@cocotb.test()
async def gaps_trigger_test(dut):

    """Test GAPS trigger"""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())  # Create a clock

    cocotb.start_soon(monitor_trig_width(dut))

    dut.hits_i[0].value = 1
    dut.reset.value = 1
    dut.event_cnt_reset.value = 1
    dut.any_hit_trigger_en_i.value = 1
    dut.trig_mask_a.value = 0
    dut.trig_mask_b.value = 0
    dut.all_triggers_are_global.value = 0
    dut.busy_i.value = 0
    dut.rb_busy_i.value = 0
    dut.force_trigger_i.value = 0

    # flush the buffers
    for _ in range(4):
        await RisingEdge(dut.clk)

    dut.reset.value = 0
    dut.event_cnt_reset.value = 0

    for _ in range(10):
        await RisingEdge(dut.clk)

    n_hits = 10

    # event loop
    for _ in range(1000):
        data = 200 * [0]
        for _ in range(n_hits):
            threshold = random.randint(0, 2)
            paddle = random.randint(0, 199)
            data[paddle] = threshold
            dut.hits_i.value = data

            if dut.global_trigger_o.value == 1:
                print(int(dut.event_cnt_o.value))

            await RisingEdge(dut.clk)


def test_trigger():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    rtl_dir = os.path.abspath(os.path.join(tests_dir, "..", "hdl"))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, f"../../../common/src/types_pkg.vhd"),
        os.path.join(tests_dir, f"../../../common/src/urand_inf.vhd"),
        os.path.join(tests_dir, f"../infra/constants.vhd"),
        os.path.join(tests_dir, f"../infra/mt_types.vhd"),
        os.path.join(tests_dir, f"../infra/components.vhd"),
        os.path.join(tests_dir, f"../infra/event_counter.vhd"),
        os.path.join(tests_dir, f"count1s.vhd"),
        os.path.join(tests_dir, f"rb_map.vhd"),
        os.path.join(tests_dir, f"integrator.vhd"),
        os.path.join(tests_dir, f"trigger.vhd"),
    ]

    os.environ["SIM"] = "ghdl"

    run(
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="trigger",
        parameters={"DEBUG": False},
        compile_args=["--std=08", "-fsynopsys"],
        toplevel_lang="vhdl",
        gui=0,
    )


if __name__ == "__main__":
    test_trigger()
