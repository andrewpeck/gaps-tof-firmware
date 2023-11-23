#!/usr/bin/env python3
import os
import random

import cocotb
from cocotb_test.simulator import run
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge

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


def set_hits(dut, value):
    for i, val in enumerate(value):
        getattr(dut, f"hits_i_{i}").value = val


@cocotb.test()
async def gaps_trigger_test_any_global(dut):
    await gaps_trigger_test(dut, trig="any", is_global=1)


@cocotb.test()
async def gaps_trigger_test_any_local(dut):
    await gaps_trigger_test(dut, trig="any", is_global=0)


@cocotb.test()
async def gaps_trigger_test_gaps_global(dut):
    await gaps_trigger_test(dut, trig="gaps", is_global=1)


@cocotb.test()
async def gaps_trigger_test_gaps_local(dut):
    await gaps_trigger_test(dut, trig="gaps", is_global=0)


@cocotb.test()
async def track_trigger_test_track_global(dut):
    await gaps_trigger_test(dut, trig="track", is_global=1)


@cocotb.test()
async def track_trigger_test_track_local(dut):
    await gaps_trigger_test(dut, trig="track", is_global=0)


@cocotb.test()
async def combine_trigger_test_combine_global(dut):
    await gaps_trigger_test(dut, trig="combine", is_global=1)


@cocotb.test()
async def combine_trigger_test_combine_local(dut):
    await gaps_trigger_test(dut, trig="combine", is_global=0)


@cocotb.test()
async def single_trigger_test_single(dut):
    await gaps_trigger_test(dut, trig="any", is_global=0, single=True)


async def gaps_trigger_test(dut, trig="any", is_global=1, rb_window=8, n_hits=30, single=False):

    """Test GAPS trigger"""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())  # Create a clock

    # cocotb.start_soon(monitor_trig_width(dut))

    dut.event_cnt_reset.value = 1

    dut.track_trigger_is_global.value = is_global
    dut.any_hit_trigger_is_global.value = is_global
    dut.read_all_channels.value = is_global

    if trig == "any" or trig == "combine" or single:
        dut.any_hit_trigger_prescale.value = 2**32 - 1
    else:
        dut.any_hit_trigger_prescale.value = 0

    if trig == "track" or trig == "combine":
        dut.track_trigger_prescale.value = 2**32 - 1
    else:
        dut.track_trigger_prescale.value = 0

    if trig == "gaps" or trig == "combine":
        dut.gaps_trigger_en.value = 1
    else:
        dut.gaps_trigger_en.value = 0

    dut.hit_thresh.value = 0

    dut.require_beta.value = 0
    dut.event_cnt_reset.value = 0
    dut.inner_tof_thresh.value = 1
    dut.outer_tof_thresh.value = 1
    dut.total_tof_thresh.value = 1

    dut.busy_i.value = 0
    dut.rb_busy_i.value = 0
    dut.rb_window_i.value = rb_window

    dut.force_trigger_i.value = 0

    dut.busy_i.value = 0
    dut.rb_busy_i.value = 0
    dut.force_trigger_i.value = 0

    set_hits(dut, 200*[0])

    # flush the buffers
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    for _ in range(128):
        await RisingEdge(dut.clk)

    dut.event_cnt_reset = 1
    await RisingEdge(dut.clk)
    dut.event_cnt_reset = 0

    # event loop
    for evt in range(10):

        # for _ in range(n_hits):
        #     threshold = random.randint(0, 2)
        #     paddle = random.randint(0, 199)
        #     data[paddle] = threshold

        data = 200 * [0]
        if single:
            data = 200 * [0]
            data[0] = 2
        else:
            data = 200 * [2]

        set_hits(dut, data)
        await RisingEdge(dut.clk)
        set_hits(dut, 200 * [0])

        for _ in range(10):
            if (dut.global_trigger_o.value == 1):
                print(f" event id = {int(dut.event_cnt_o.value)}")

                assert int(dut.event_cnt_o.value) == evt + 1

                trig_source = {"any": 1 << 6,
                               "gaps": 1 << 5,
                               "track": 1 << 8,
                               "combine": 1 << 8 | 1 << 5 | 1 << 6}[trig]

                assert int(dut.trig_sources_o.value) == trig_source

                assert int(dut.hits_o_0.value) == 2

                if (is_global):
                    assert int(dut.trigger_2.pedestal_trig_latch.value) == 1
                else:
                    assert int(dut.trigger_2.pedestal_trig_latch.value) == 0
                break

            await RisingEdge(dut.clk)

        # n cycles to integrate the ltb channels
        for _ in range(rb_window):
            await RisingEdge(dut.clk)

        # 1 cycle to copy the outputs
        await RisingEdge(dut.clk)

        assert dut.rb_trigger_o.value == 1
        if is_global:
            assert int(dut.rb_ch_bitmap_o.value) == \
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        elif single:
            assert int(dut.rb_ch_bitmap_o.value) == 0b11
        else:
            assert int(dut.rb_ch_bitmap_o.value) == \
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

        await FallingEdge(dut.trigger_2.dead)


def test_trigger():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
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
        os.path.join(tests_dir, f"trigger_top.vhd"),
    ]

    os.environ["SIM"] = "ghdl"

    run(
        vhdl_sources=vhdl_sources,
        module=module,
        toplevel="trigger_top",
        parameters={"DEBUG": False},
        compile_args=["--std=08"],
        simulation_args=["--ieee-asserts=disable"],
        toplevel_lang="vhdl",
        gui=0,
        waves=1,
    )


if __name__ == "__main__":
    test_trigger()
