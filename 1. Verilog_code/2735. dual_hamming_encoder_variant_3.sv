//SystemVerilog
module dual_hamming_encoder(
    input clk, rst_n,
    input [3:0] data_a, data_b,
    output reg [6:0] encoded_a, encoded_b
);
    // 使用条件运算符替代if-else结构
    always @(posedge clk or negedge rst_n) begin
        encoded_a[0] <= !rst_n ? 1'b0 : (data_a[0] ^ data_a[1] ^ data_a[3]);
        encoded_a[1] <= !rst_n ? 1'b0 : (data_a[0] ^ data_a[2] ^ data_a[3]);
        encoded_a[2] <= !rst_n ? 1'b0 : data_a[0];
        encoded_a[3] <= !rst_n ? 1'b0 : (data_a[1] ^ data_a[2] ^ data_a[3]);
        encoded_a[4] <= !rst_n ? 1'b0 : data_a[1];
        encoded_a[5] <= !rst_n ? 1'b0 : data_a[2];
        encoded_a[6] <= !rst_n ? 1'b0 : data_a[3];
        
        encoded_b[0] <= !rst_n ? 1'b0 : (data_b[0] ^ data_b[1] ^ data_b[3]);
        encoded_b[1] <= !rst_n ? 1'b0 : (data_b[0] ^ data_b[2] ^ data_b[3]);
        encoded_b[2] <= !rst_n ? 1'b0 : data_b[0];
        encoded_b[3] <= !rst_n ? 1'b0 : (data_b[1] ^ data_b[2] ^ data_b[3]);
        encoded_b[4] <= !rst_n ? 1'b0 : data_b[1];
        encoded_b[5] <= !rst_n ? 1'b0 : data_b[2];
        encoded_b[6] <= !rst_n ? 1'b0 : data_b[3];
    end
endmodule