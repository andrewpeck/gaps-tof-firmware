#!/usr/bin/env python3
import os
import random

import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb_test.simulator import run

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


async def busy_logic(dut, timer=1):
    dut.busy_i.value = 0
    while True:
        await RisingEdge(dut.global_trigger_o)
        await RisingEdge(dut.clk)
        dut.busy_i.value = 1
        await Timer(timer, units="us")
        dut.busy_i.value = 0


def set_hits(dut, value):
    for i, val in enumerate(value):
        getattr(dut, f"hits_i_{i}").value = val


@cocotb.test()
async def gaps_trigger_test_any_global(dut):
    await gaps_trigger_test(dut, trig="any", is_global=1)


@cocotb.test()
async def gaps_trigger_test_rb_window(dut):
    await gaps_trigger_test(dut, trig="any", is_global=1, rb_window=0)
    await gaps_trigger_test(dut, trig="any", is_global=1, rb_window=1)
    await gaps_trigger_test(dut, trig="any", is_global=1, rb_window=10)
    await gaps_trigger_test(dut, trig="any", is_global=1, rb_window=30)


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
async def single_channel_trigger_test_global(dut):
    await gaps_trigger_test(dut, trig="any", is_global=1, single_channel=True)


@cocotb.test()
async def single_channel_trigger_test_local(dut):
    await gaps_trigger_test(dut, trig="any", is_global=0, single_channel=True)


async def reset(dut):
    # flush the buffers
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    for _ in range(128):
        await RisingEdge(dut.clk)


async def init(dut):

    dut.reset.value = 0

    dut.event_cnt_reset.value = 1

    dut.gaps_trigger_prescale.value = 0
    dut.any_hit_trigger_prescale.value = 0
    dut.track_trigger_prescale.value = 0
    dut.track_central_prescale.value = 0
    dut.track_umb_central_prescale.value = 0

    dut.track_central_is_global.value = 1
    dut.track_umb_central_is_global.value = 1
    dut.track_trigger_is_global.value = 1
    dut.any_hit_trigger_is_global.value = 1

    dut.hit_thresh.value = 0

    dut.read_all_channels.value = 0

    dut.gaps_trigger_en.value = 0
    dut.require_beta.value = 0
    dut.cube_side_thresh.value = 0
    dut.cube_top_thresh.value = 0
    dut.cube_bot_thresh.value = 0
    dut.cube_corner_thresh.value = 0
    dut.umbrella_thresh.value = 0
    dut.umbrella_center_thresh.value = 0
    dut.cortina_thresh.value = 0

    dut.busy_i.value = 0
    dut.rb_busy_i.value = 0
    dut.rb_window_i.value = 0

    dut.cube_side_thresh.value = 1
    dut.configurable_trigger_en.value = 0
    dut.force_trigger_i.value = 0
    set_hits(dut, [0]*200)


# @cocotb.test()
async def prescale_test(dut):

    import matplotlib.pyplot as plt

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())  # Create a clock
    cocotb.start_soon(busy_logic(dut, 32))

    await init(dut)
    await reset(dut)

    n_steps = 10
    n_triggers = 50

    x = [0]*n_steps
    y = [0]*n_steps

    hit_rate = 200  # kHz
    p = hit_rate/100000

    set_hits(dut, [0]*200)

    rands = []

    for step in range(n_steps):

        gate_open_cnt = 0
        gen_trigger_cnt = 0
        trigger_cnt = 0
        blocked_trigger_cnt = 0
        lost_trigger_cnt = 0
        n_clks = 0
        prescale = int(step / (n_steps-1) * (2**32-1))
        dut.any_hit_trigger_prescale.value = prescale

        # reseed
        random.seed(0)

        breakloop = 0

        while True:

            urand = dut.trigger_2.any_hit_trigger_urand.value
            en = dut.trigger_2.any_trigger_en.value
            rands.append(urand)

            if gen_trigger_cnt < n_triggers:
                if random.uniform(0, 1) <= p:
                    getattr(dut, "hits_i_0").value = 1
                    gen_trigger_cnt += 1
                else:
                    getattr(dut, "hits_i_0").value = 0
            else:
                getattr(dut, "hits_i_0").value = 0
                breakloop += 1
                if breakloop == 128:
                    breakloop = 0
                    break

            await RisingEdge(dut.clk)
            if (dut.global_trigger_o.value != 0):
                trigger_cnt += 1
            if (dut.lost_trigger_o.value != 0):
                lost_trigger_cnt += 1
            if (dut.any_trigger_blocked_o.value != 0):
                blocked_trigger_cnt += 1
            gate_open_cnt += en

            n_clks += 1

        total = trigger_cnt + blocked_trigger_cnt + lost_trigger_cnt
        time = (n_clks * 10E-9 * 1000)
        x[step] = prescale
        # y[step]=trigger_cnt / n_triggers # fraction
        y[step] = trigger_cnt / time  # kHz
        print(f'{step=} {time=} {y[step]} gen={gen_trigger_cnt} vs account={total} ({trigger_cnt=} {blocked_trigger_cnt=} {lost_trigger_cnt=}) cycle={gate_open_cnt/n_clks * 100}', flush=True)

    plt.plot(x, y)
    plt.show()


async def gaps_trigger_test(dut, trig="any", is_global=1, rb_window=8, n_hits=30, single_channel=False):
    """Test GAPS trigger"""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())  # Create a clock

    # cocotb.start_soon(monitor_trig_width(dut))
    cocotb.start_soon(busy_logic(dut))

    dut.event_cnt_reset.value = 1

    dut.track_central_is_global.value = is_global
    dut.track_umb_central_is_global.value = is_global
    dut.track_trigger_is_global.value = is_global
    dut.any_hit_trigger_is_global.value = is_global
    dut.cube_side_thresh.value = is_global
    dut.configurable_trigger_en.value = 0
    dut.cube_side_thresh.value = 0
    dut.cube_top_thresh.value = 0
    dut.cube_bot_thresh.value = 0
    dut.cube_corner_thresh.value = 0
    dut.umbrella_thresh.value = 0
    dut.umbrella_center_thresh.value = 0
    dut.cortina_thresh.value = 0

    dut.read_all_channels.value = is_global

    if trig == "any" or trig == "combine" or single_channel:
        dut.any_hit_trigger_prescale.value = 2**32 - 1
    else:
        dut.any_hit_trigger_prescale.value = 0

    if trig == "central" or trig == "combine":
        dut.track_central_prescale.value = 2**32 - 1
    else:
        dut.track_central_prescale.value = 0

    if trig == "umb_central" or trig == "combine":
        dut.track_umb_central_prescale.value = 2**32 - 1
    else:
        dut.track_umb_central_prescale.value = 0

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

    dut.event_cnt_reset.value = 1
    await RisingEdge(dut.clk)
    dut.event_cnt_reset.value = 0

    # event loop
    for evt in range(10):

        # for _ in range(n_hits):
        #     threshold = random.randint(0, 2)
        #     paddle = random.randint(0, 199)
        #     data[paddle] = threshold

        data = 200 * [0]

        channel = 9

        if single_channel:
            data = 200 * [0]
            data[channel] = 2
        else:
            data = 200 * [2]

        if dut.busy_i.value == 1:
            await FallingEdge(dut.busy_i)

        set_hits(dut, data)
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        set_hits(dut, 200 * [0])

        for _ in range(10):
            if (dut.global_trigger_o.value == 1):
                print(f" event id = {int(dut.event_cnt_o.value)}")

                assert int(dut.event_cnt_o.value) == evt + 1

                def get_trig_source(trigger, value):
                    if trigger == 'any':
                        return 1 & (value >> 6)
                    elif trigger == 'gaps':
                        return 1 & (value >> 5)
                    elif trigger == 'track':
                        return 1 & (value >> 8)
                    elif trigger == 'central':
                        return 1 & (value >> 9)
                    elif trigger == 'umb_central':
                        return 1 & (value >> 4)
                    elif trigger == 'combine':
                        return 0x3f & (value >> 4)

                assert get_trig_source(
                    trig,
                    int(dut.trig_sources_o.value)
                ) > 0

                assert int(getattr(dut, f"hits_o_{channel}").value) == 2

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
        else:
            if not single_channel:
                assert int(dut.rb_ch_bitmap_o.value) > 0

        #     assert int(dut.rb_ch_bitmap_o.value) == 0b11
        # else:
        #     assert int(dut.rb_ch_bitmap_o.value) == \
        #         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

        await FallingEdge(dut.trigger_2.dead)


def test_trigger():

    tests_dir = os.path.abspath(os.path.dirname(__file__))
    module = os.path.splitext(os.path.basename(__file__))[0]

    vhdl_sources = [
        os.path.join(tests_dir, f"../../../common/src/types_pkg.vhd"),
        os.path.join(tests_dir, f"../../../common/src/urand_inf.vhd"),
        os.path.join(tests_dir, f"../../../common/src/oneshot.vhd"),
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
        sim_args=["--ieee-asserts=disable"],
        toplevel_lang="vhdl",
        gui=1,
        waves=1,
    )


if __name__ == "__main__":
    test_trigger()
