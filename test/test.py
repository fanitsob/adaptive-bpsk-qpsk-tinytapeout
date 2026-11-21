import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer


@cocotb.test()
async def test_adaptive_modem(dut):

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())

    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 2)

    assert (int(dut.uo_out.value) >> 3) & 1 == 0
    assert int(dut.uio_oe.value) == 255

    async def send_window(errors, expected_mode):

        for i in range(128):
            await FallingEdge(dut.clk)

            reference = i % 2
            received = reference ^ int(i < errors)

            # ui[5] = comparison valid
            # ui[3] = received bit
            # ui[2] = reference bit
            dut.ui_in.value = (
                (1 << 5)
                | (received << 3)
                | (reference << 2)
            )

            await RisingEdge(dut.clk)
            await Timer(8, units="ns")

            # Check final sample
            if i == 127:
                assert (int(dut.uo_out.value) >> 5) & 1 == 1
                assert int(dut.uio_out.value) == errors

        await FallingEdge(dut.clk)
        dut.ui_in.value = 0

        await ClockCycles(dut.clk, 2)
        await Timer(8, units="ns")

        mode = (int(dut.uo_out.value) >> 3) & 1

        assert mode == expected_mode, (
            f"errors={errors}: expected mode={expected_mode}, "
            f"actual mode={mode}"
        )

        assert int(dut.uio_out.value) == errors

        dut._log.info(
            f"Errors={errors}, mode={mode}: PASS"
        )

    # First good window: remain BPSK
    await send_window(0, 0)

    # Second good window: switch to QPSK
    await send_window(1, 1)

    # Intermediate errors: remain QPSK
    await send_window(5, 1)

    # High errors: immediately switch to BPSK
    await send_window(12, 0)

    # First good window: remain BPSK
    await send_window(2, 0)

    # Intermediate errors cancel pending confirmation
    await send_window(5, 0)

    # First good window again: remain BPSK
    await send_window(0, 0)

    # Second consecutive good window: switch QPSK
    await send_window(1, 1)

    # High errors: return immediately to BPSK
    await send_window(8, 0)
    # Check I/Q mapping in BPSK mode
    await FallingEdge(dut.clk)
    dut.ui_in.value = (1 << 4)  # valid=1, data=00

    await RisingEdge(dut.clk)
    await Timer(8, units="ns")

    out = int(dut.uo_out.value)

    assert (out & 1) == 1       # I sign
    assert ((out >> 1) & 1) == 0 # Q sign
    assert ((out >> 2) & 1) == 1 # valid out

    dut._log.info("ALL ADAPTIVE MODEM TESTS PASSED")
