import cocotb
import cocotb.wavedrom
from cocotb.triggers import Timer,RisingEdge

from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.drivers import BitDriver
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure,ReturnValue

simdone = 0 


class Driver_RMII_MAC(): 
    def __init__(self,dut,RX_ER,CRS_DV,RXD,REF_CLK,TXD,TX_EN):
        self.dut     = dut 
        self.rx_err  = RX_ER
        self.crs_dv  = CRS_DV 
        self.ref_clk = REF_CLK 
        self.rxd     = RXD
        self.txd     = TXD
        self.tx_en   = TX_EN 
        self.speed   = 100
        self.killclk = 0 

    @cocotb.coroutine 
    def Configure(self,speed):
        if(speed != 10 or speed != 100): 
            print "Error, invalid speed selection"
        else: 
            self.speed = speed

        self.txd     <= 0 
        self.tx_en   <= 0
        self.ref_clk <= 0

        yield Timer(10000)
     
    def KillRefClk(self):
        self.killclk = 1 

    @cocotb.coroutine
    def GenRefClk(self): 
        #set clock period in ps 
        if(self.speed == 100): 
            self.period = 20001
        else:
            self.period = 200000
        
        while(self.killclk != 1):
            self.ref_clk <= 0 
            yield Timer(self.period/2) 
            self.ref_clk <= 1 
            yield Timer(self.period/2) 

    @cocotb.coroutine 
    def WriteByte(self,byte,final,idle):
        if(idle == 0):
            self.tx_en <= 1
        
#        print hex(byte) 
        halfnib  = (byte & 0x3)
#        print "halfnib: " + hex(halfnib)
        self.txd <= halfnib
        yield RisingEdge(self.ref_clk) 

        halfnib  = ((byte >> 2) & 0x3)
#        print "halfnib: " + hex(halfnib)
        self.txd <= halfnib
        yield RisingEdge(self.ref_clk) 

        halfnib  = ((byte >> 4) & 0x3)
#        print "halfnib: " + hex(halfnib)
        self.txd <= halfnib
        yield RisingEdge(self.ref_clk) 

        halfnib  = ((byte >> 6) & 0x3)
#        print "halfnib: " + hex(halfnib)
        self.txd <= halfnib
        yield RisingEdge(self.ref_clk) 

        if(final == 1): 
            self.tx_en <= 0 


    @cocotb.coroutine 
    def SendFrame(self,frame):
        
        for i in range(len(frame)): 
            if(i != (len(frame)-1)):
                yield self.WriteByte(frame[i],0,0)
            else:
                yield self.WriteByte(frame[i],1,0)
        
        for i in range(96): 
            self.WriteByte(0x00,0,1)


    @cocotb.coroutine
    def ReadByte(self): 
        byte = 0x0

        byte = int(self.rxd.value)
        yield RisingEdge(self.ref_clk) 
 
        byte = byte | int((self.rxd.value << 2))
        yield RisingEdge(self.ref_clk) 
 
        byte = byte | int((self.rxd.value << 4))
        yield RisingEdge(self.ref_clk) 
 
        byte = byte | int((self.rxd.value << 6))
        yield RisingEdge(self.ref_clk) 
 
        raise ReturnValue(byte)


    @cocotb.coroutine 
    def ReadFrame(self): 
        
        #wait for idle state to go away 
        idle = 1 
        while(idle == 1): 
            yield RisingEdge(self.ref_clk) 
            if(self.crs_dv.value == 1 and self.rxd.value != 0):
                idle = 0 
        
        #wait for sfd 
        precount  = 0 
        sfd       = 0 
        bytecount = 0
        while True:
            byte = yield self.ReadByte()
            #log preamble byte detect
            if(byte == 0x55):
                precount += 1 

            elif(byte == 0xD5): 
                sfd = 1
                break;

            else: 
                precount = 0 
                sfd = 0 
            
            bytecount += 1
            #arbitrary cutoff if failed to receive data
            if(bytecount > 70):
                break;

        #check if we failed to lock to sfd
        if(bytecount > 20):
            raise ReturnValue([-1])

        if(precount == 7 and sfd == 1): 
            self.dut._log.info("sfd detected")

        ret = []
        while(self.crs_dv.value == 1): 
            byte = yield self.ReadByte()
            ret.append(byte) 

        #return array representation of frame 
        raise ReturnValue(ret)





            
            






        
