`timescale 1ps/1ps

module top (
    rst_l,
    sgmii_tx, 
    sgmii_rx,

    mii_clk,
    rmii_refclk, 
    rmii_txd,
    rmii_tx_en,
    rmii_rx_er,
    rmii_crs_dv,
    rmii_rxd

    );

input rst_l;
output sgmii_tx;
input  sgmii_rx; 
input mii_clk; 
input rmii_refclk;
input [1:0] rmii_txd;
input rmii_tx_en;


output rmii_rx_er;
output rmii_crs_dv;
output [1:0] rmii_rxd; 



//internal wires
wire mii_rx_dv;
wire mii_rx_er;
wire mii_rx_crs;
wire mii_rx_col;
wire [3:0] mii_rxd;

wire [3:0] mii_txd;
wire mii_tx_en;
wire mii_tx_er;

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
    .mii_rxd     (mii_rxd),
    .mii_rx_dv   (mii_rx_dv),
    .mii_rx_er   (mii_rx_er),
    .mii_crs     (mii_rx_crs),
    .mii_col     (mii_rx_col), 

    .mii_txclk   (mii_clk), 
    .mii_txd     (mii_txd),
    .mii_tx_en   (mii_tx_en), 
    .mii_tx_er   (mii_tx_er)
);


wire [9:0] tbi_loop;
mii_sgmii sgmii
(
    .rst_l(rst_l),
    .tbi_out(tbi_loop),
    .tbi_in(tbi_loop), 
    .mii_rxclk(mii_clk),
    .mii_rxd(mii_rxd),
    .mii_rx_dv(mii_rx_dv),
    .mii_rx_er(mii_rx_er),
    .mii_rx_crs(mii_rx_crs),
    .mii_rx_col(mii_rx_col),

    .mii_txclk(mii_clk), 
    .mii_txd(mii_txd),
    .mii_tx_en(mii_tx_en),
    .mii_tx_er(mii_tx_er)
);

//`ifdef COCOTB_SIM 
initial begin 
  $dumpfile ("waveform.vcd"); 
  $dumpvars (0,top);   
  #1; 
end 
//`endif 

endmodule
