module encoder_8b10b (
    clk, 
    rst_l,
 
    data_in,
    k_in, 
    
    data_out,
    k_err
    );

input clk; 
input rst_l;
input [7:0] data_in;
input k_in;

output [9:0] data_out;
output k_err;

reg [7:0] data_in_r;
reg k_in_r;

reg  [3:0] bits_y_enc;
wire [3:0] bits_y_enc_i;
reg  [5:0] bits_x_enc;
wire [5:0] bits_x_enc_i;

wire [1:0] disp_y;
wire [1:0] disp_x;


reg [6:0] bits_x_table [0:32];
reg [4:0] bits_y_table [0:8];

reg [1:0] cur_disp;

reg [9:0] enc_out;
reg priv_disp;

//initialize tables 
always @ (rst_l) begin
    if(rst_l == 1'b0) begin
        bits_x_table[0] = 7'b0100111;
        bits_x_table[1] = 7'b0011101;
        bits_x_table[2] = 7'b0101101;
        bits_x_table[3] = 7'b1110001;
        bits_x_table[4] = 7'b0110101;
        bits_x_table[5] = 7'b1101001;
        bits_x_table[6] = 7'b1011001;
        bits_x_table[7] = 7'b0111000;
        bits_x_table[8] = 7'b0111001;
        bits_x_table[9] = 7'b1100101;
        bits_x_table[10] = 7'b1010101;
        bits_x_table[11] = 7'b1110100;
        bits_x_table[12] = 7'b1001101;
        bits_x_table[13] = 7'b1101100;
        bits_x_table[14] = 7'b1011100;
        bits_x_table[15] = 7'b0010111;
        bits_x_table[16] = 7'b0011011;
        bits_x_table[17] = 7'b1100011;
        bits_x_table[18] = 7'b1010011;
        bits_x_table[19] = 7'b1110010;
        bits_x_table[20] = 7'b1001011;
        bits_x_table[21] = 7'b1101010;
        bits_x_table[22] = 7'b1011010;
        bits_x_table[23] = 7'b0111010;
        bits_x_table[24] = 7'b0110011;
        bits_x_table[25] = 7'b1100110;
        bits_x_table[26] = 7'b1010110;
        bits_x_table[27] = 7'b0110110;
        bits_x_table[28] = 7'b1001110;
        bits_x_table[29] = 7'b0101110;
        bits_x_table[30] = 7'b0011110;
        bits_x_table[31] = 7'b0101011;

        bits_y_table[0] = 5'b00100;
        bits_y_table[1] = 5'b11001;
        bits_y_table[2] = 5'b10101;
        bits_y_table[3] = 5'b00011;
        bits_y_table[4] = 5'b00010;
        bits_y_table[5] = 5'b11010;
        bits_y_table[6] = 5'b10110;
        bits_y_table[7] = 5'b00001;

    end
end

//register input data and control
always @ (posedge(clk)) begin
    if(rst_l == 1'b0) begin     
        data_in_r = 8'b00000000;
        k_in_r    = 1'b0;
    end
    else if (clk == 1'b1) begin
        bits_y_enc = bits_y_table[data_in[7:5]];
        bits_x_enc = bits_x_table[data_in[4:0]];
        k_in_r    = k_in;
    end
end     


//assign vectors based on disp 
//if current disp is even, assign it without mods 
//if current disp is odd and the previous disp was odd, change to even

always @ (prev_disp,bits_y_enc[4],bits_x_enc[7]) begin
    if(!prev_disp) begin        

    end 
    else begin

    end    

end

assign bits_y_enc_i = ((!prev_disp) & (!bits_y_enc[4])) ? bits_y_enc[3:0] : (^bits_y_enc[3:0])
assign bits_x_enc_i = ((!prev_disp) & (!bits_x_enc[7])) ? bits_x_enc[6:0] : (^bits_x_enc[6:0])



always @ (posedge(clk)) begin
    if(rst_l == 1'b0) begin
        prev_disp = 1'b0;
    end
        
end

endmodule 
