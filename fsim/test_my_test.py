import cocotb
import cocotb.wavedrom
from cocotb.triggers import Timer,RisingEdge

from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.drivers import BitDriver
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure


from rmii import Driver_RMII_MAC

import random

simdone = 0 


eth_preamble = [0x55,0x55,0x55,0x55,0x55,0x55,0x55,0xD5]

eth_payload  = [0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07]


#frames2Test = [eth_payload,eth_payload,eth_payload]

def MakeFrames(n): 
    frames = []
    for f in range(n): 
        size = int(random.random()*1518) 
        temp = []
        for i in range(size): 
            temp.append(int(random.random()*255))

        frames.append(temp)


    return frames
    


@cocotb.coroutine
def sysclk(sig, period):
    global simdone
    while(simdone != 1):  
        sig <= 0 
        yield Timer(period/2) 
        sig <= 1 
        yield Timer(period/2)



@cocotb.test()
def my_first_test(dut):
    global simdone 
    failed = 0 

    runtime = 100000
    dut._log.info("Running test!")
    dut.rst_l = 0 
    
    rmii_mac = Driver_RMII_MAC(dut,dut.rmii_rx_er,dut.rmii_crs_dv,dut.rmii_rxd,
                               dut.rmii_refclk,dut.rmii_txd,dut.rmii_tx_en);
   
    yield rmii_mac.Configure(100) 
    mii_mac_clk  = cocotb.fork(sysclk(dut.mii_clk,40000))
    rmii_mac_clk = cocotb.fork(rmii_mac.GenRefClk()) 

    yield Timer(80000)
    dut.rst_l = 1 
    dut._log.info("Releasing Reset")

    yield Timer(20000)

    failed = 0 
    frames = MakeFrames(15)
    for x in frames:
        rmii_mac_send = cocotb.fork(rmii_mac.SendFrame(eth_preamble+x))
        rxframe = yield rmii_mac.ReadFrame()
    
        if(rxframe == x):
            dut._log.info("Frame Matched - size: %d" % len(x)) 

        else: 
            dut._log.info("Frame Error Occurred - orig size: %d, obeserved size: %d" % (len(x),len(rxframe)))
            failed = 1
            break

        yield rmii_mac_send.join()

    
    simdone = 1
    rmii_mac.KillRefClk()

    yield mii_mac_clk.join()
    yield rmii_mac_clk.join()
    dut._log.info("Test Complete!")

    if(failed): 
        raise TestFailure()
    

