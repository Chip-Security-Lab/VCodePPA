//SystemVerilog
module crc5_comb (
    input [4:0] data_in,
    output reg [4:0] crc_out
);
    // 使用桶形移位器结构实现左移1位操作
    wire [4:0] shifted_data;
    assign shifted_data[0] = 1'b0;        // 左移1位后最低位为0
    assign shifted_data[1] = data_in[0];
    assign shifted_data[2] = data_in[1];
    assign shifted_data[3] = data_in[2];
    assign shifted_data[4] = data_in[3];
    
    // 使用if-else结构替代条件运算符
    always @(*) begin
        if (data_in[4]) begin
            crc_out = shifted_data ^ 5'h15;
        end else begin
            crc_out = shifted_data;
        end
    end
endmodule