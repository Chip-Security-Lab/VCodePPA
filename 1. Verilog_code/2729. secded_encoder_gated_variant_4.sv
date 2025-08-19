//SystemVerilog
module secded_encoder_gated(
    input clk, en, rst,
    input [3:0] data,
    output reg [7:0] code
);
    wire gated_clk;
    reg [3:0] data_reg;
    reg [6:0] hamming_code;
    reg overall_parity;
    
    assign gated_clk = clk & en;
    
    always @(posedge gated_clk or posedge rst) begin
        data_reg <= rst ? 4'b0 : data;
    end
    
    always @(posedge gated_clk or posedge rst) begin
        hamming_code[0] <= rst ? 1'b0 : (data_reg[0] ^ data_reg[1] ^ data_reg[3]);
        hamming_code[1] <= rst ? 1'b0 : (data_reg[0] ^ data_reg[2] ^ data_reg[3]);
        hamming_code[2] <= rst ? 1'b0 : data_reg[0];
        hamming_code[3] <= rst ? 1'b0 : (data_reg[1] ^ data_reg[2] ^ data_reg[3]);
        hamming_code[4] <= rst ? 1'b0 : data_reg[1];
        hamming_code[5] <= rst ? 1'b0 : data_reg[2];
        hamming_code[6] <= rst ? 1'b0 : data_reg[3];
        overall_parity <= rst ? 1'b0 : ^hamming_code;
        code <= rst ? 8'b0 : {overall_parity, hamming_code};
    end
endmodule