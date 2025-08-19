module bit_shuffler #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [1:0] shuffle_mode,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        case (shuffle_mode)
            2'b00: data_out = data_in;  // 不变
            2'b01: data_out = {data_in[3:0], data_in[7:4]};  // 交换半字节
            2'b10: data_out = {data_in[1:0], data_in[7:2]};  // 循环右移2位
            2'b11: data_out = {data_in[5:0], data_in[7:6]};  // 循环右移6位
        endcase
    end
endmodule