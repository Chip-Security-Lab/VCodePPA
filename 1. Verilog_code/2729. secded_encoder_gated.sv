module secded_encoder_gated(
    input clk, en, rst,
    input [3:0] data,
    output reg [7:0] code // 7 bits + overall parity
);
    wire gated_clk;
    reg [6:0] hamming_code;
    
    assign gated_clk = clk & en;
    
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            hamming_code <= 7'b0;
            code <= 8'b0;
        end else begin
            hamming_code[0] <= data[0] ^ data[1] ^ data[3];
            hamming_code[1] <= data[0] ^ data[2] ^ data[3];
            hamming_code[2] <= data[0];
            hamming_code[3] <= data[1] ^ data[2] ^ data[3];
            hamming_code[4] <= data[1];
            hamming_code[5] <= data[2];
            hamming_code[6] <= data[3];
            code <= {^hamming_code, hamming_code}; // Add overall parity
        end
    end
endmodule