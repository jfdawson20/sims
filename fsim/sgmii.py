import cocotb
import cocotb.wavedrom
from cocotb.triggers import Timer,RisingEdge

from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.drivers import BitDriver
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure

simdone = 0 

@cocotb.coroutine
def sysclk(sig, period, count):
    for c in range(count): 
        sig <= 0 
        yield Timer(period/2) 
        sig <= 1 
        yield Timer(period/2)

    global simdone
    simdone = 1



@cocotb.test()
def my_first_test(dut):
    global simdone 

    runtime = 100000
    dut._log.info("Running test!")
    dut.rst_l = 0 
   
    runclk = cocotb.fork(sysclk(dut.clk, 500,runtime))
   
    yield Timer(2000) 
    dut._log.info("Releasing Reset")
    dut.rst_l = 1 
    
    
    clk_1ms_val = dut.clk1ms.value 
    yield Timer(0.5,'ms')

    failed = 0 
    while(simdone != 1):
        if(clk_1ms_val != dut.clk1ms.value):
            dut._log.info("Good Clock Transition Detected - PASS, Clock State: %d,%d",clk_1ms_val,dut.clk1ms.value) 
        else:
            failed = 1
            dut._log.info("No Clock Transition Detected - FAIL, Clock State: %d,%d",clk_1ms_val,dut.clk1ms.value) 
            
    
        clk_1ms_val = dut.clk1ms.value 
        yield Timer(0.5,'ms')

    yield runclk.join()
    dut._log.info("Test Complete!")
    
    if(failed):
        raise TestFailure()
