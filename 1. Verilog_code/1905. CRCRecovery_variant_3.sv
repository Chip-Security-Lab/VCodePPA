//SystemVerilog
module CRCRecovery #(parameter WIDTH=8) (
    input clk,
    input [WIDTH+3:0] coded_in, // 4-bit CRC
    output reg [WIDTH-1:0] data_out,
    output reg crc_error
);
    // 分离数据和CRC部分
    wire [WIDTH-1:0] data = coded_in[WIDTH-1:0];
    wire [3:0] received_crc = coded_in[WIDTH+3:WIDTH];
    
    // 优化CRC校验计算 - 直接计算校验结果
    wire [3:0] calc_crc;
    assign calc_crc = received_crc ^ {
        ^data[WIDTH-1:3],
        ^data[WIDTH-2:2],
        ^data[WIDTH-3:1],
        ^data[WIDTH-4:0]
    };
    
    // 错误检测优化 - 使用归约运算，避免多级OR门
    wire error_detected;
    assign error_detected = |calc_crc;
    
    // 寄存器逻辑优化
    always @(posedge clk) begin
        crc_error <= error_detected;
        data_out <= {WIDTH{error_detected}} | (data & {WIDTH{~error_detected}});
    end
endmodule