//SystemVerilog
module error_injection_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire inject_error,
    input wire [2:0] error_bit,
    output reg [7:0] crc_out
);
    parameter [7:0] POLY = 8'h07;
    
    wire [7:0] modified_data;
    wire crc_feedback;
    wire [7:0] next_crc;
    
    // 简化错误注入逻辑，使用条件运算符
    assign modified_data = inject_error ? (data ^ (8'h1 << error_bit)) : data;
    
    // 提取反馈位简化CRC计算
    assign crc_feedback = crc_out[7] ^ modified_data[0];
    assign next_crc = {crc_out[6:0], 1'b0} ^ (crc_feedback ? POLY : 8'h00);
    
    always @(posedge clk) begin
        if (rst)
            crc_out <= 8'h00;
        else if (data_valid)
            crc_out <= next_crc;
    end
endmodule