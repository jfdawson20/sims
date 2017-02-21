`timescale 1ps/1ps

module top (
    rst_l,
    mii_clk,
    rmii_refclk, 
    rmii_txd,
    rmii_tx_en,
    rmii_rx_er,
    rmii_crs_dv,
    rmii_rxd

    );

input rst_l;
input mii_clk; 
input rmii_refclk;
input [1:0] rmii_txd;
input rmii_tx_en;


output rmii_rx_er;
output rmii_crs_dv;
output [1:0] rmii_rxd; 



//internal wires
wire mii_tx_en_to_crs;
wire [3:0] data;

rmii_mii rmii_conv
(   
    //rmii 
    .rmii_refclk (rmii_refclk), 
    .rst_l       (rst_l),
    
    .rmii_txd    (rmii_txd),
    .rmii_tx_en  (rmii_tx_en),

    .rmii_rx_er  (rmii_rx_er),
    .rmii_crs_dv (rmii_crs_dv),
    .rmii_rxd    (rmii_rxd),

    //mii 
    .mii_rxclk   (mii_clk),
    .mii_rxd     (data),
    .mii_rx_dv   (mii_tx_en_to_crs),
    .mii_rx_er   (1'b0),
    .mii_crs     (mii_tx_en_to_crs),
    .mii_col     (1'b0), 

    .mii_txclk   (mii_clk), 
    .mii_txd     (data),
    .mii_tx_en   (mii_tx_en_to_crs), 
    .mii_tx_er   ()
);


//`ifdef COCOTB_SIM 
initial begin 
  $dumpfile ("waveform.vcd"); 
  $dumpvars (0,top);   
  #1; 
end 
//`endif 

endmodule
