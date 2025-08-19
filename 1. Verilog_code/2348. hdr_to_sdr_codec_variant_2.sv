//SystemVerilog
`timescale 1ns / 1ps

module hdr_to_sdr_codec (
    input [15:0] hdr_pixel,
    input [1:0] method_sel,  // 0: Linear, 1: Log, 2: Exp, 3: Custom
    input [7:0] custom_param,
    output reg [7:0] sdr_pixel
);
    wire [7:0] log_result;
    wire [15:0] custom_mult_result;
    wire [15:0] barrel_shifted_linear;
    wire [15:0] barrel_shifted_custom;
    
    // 实例化优先级编码器模块
    priority_encoder #(
        .WIDTH(16),
        .OUTPUT_WIDTH(4)
    ) log_encoder (
        .data(hdr_pixel),
        .position(log_result[7:4]),
        .valid() // 未使用
    );
    
    // 填充低位为0
    assign log_result[3:0] = 4'b0000;
    
    // 乘法结果
    assign custom_mult_result = hdr_pixel * custom_param;
    
    // 桶形移位器 - 线性截断 (右移8位)
    barrel_shifter_right #(
        .WIDTH(16),
        .SHIFT_BITS(4)
    ) linear_shifter (
        .data_in(hdr_pixel),
        .shift_amount(4'd8),
        .data_out(barrel_shifted_linear)
    );
    
    // 桶形移位器 - 自定义缩放 (右移8位)
    barrel_shifter_right #(
        .WIDTH(16),
        .SHIFT_BITS(4)
    ) custom_shifter (
        .data_in(custom_mult_result),
        .shift_amount(4'd8),
        .data_out(barrel_shifted_custom)
    );
    
    always @(*) begin
        case (method_sel)
            2'b00: sdr_pixel = barrel_shifted_linear[7:0];  // 桶形移位器实现的线性截断
            2'b01: sdr_pixel = log_result;  // Log approximation
            2'b10: sdr_pixel = (hdr_pixel > 16'h00FF) ? 8'hFF : hdr_pixel[7:0]; // Clipping
            2'b11: sdr_pixel = barrel_shifted_custom[7:0]; // 桶形移位器实现的自定义缩放
            default: sdr_pixel = hdr_pixel[7:0];
        endcase
    end
endmodule

// 通用优先级编码器模块
module priority_encoder #(
    parameter WIDTH = 16,          // 输入位宽
    parameter OUTPUT_WIDTH = 4      // 输出位宽
)(
    input [WIDTH-1:0] data,
    output reg [OUTPUT_WIDTH-1:0] position,
    output reg valid
);
    integer i;
    
    always @(*) begin
        valid = 1'b0;
        position = {OUTPUT_WIDTH{1'b0}};
        
        // 使用循环实现优先级编码，提高代码复用性
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (data[i] && !valid) begin
                position = i[OUTPUT_WIDTH-1:0];
                valid = 1'b1;
            end
        end
    end
endmodule

// 桶形移位器模块 - 右移
module barrel_shifter_right #(
    parameter WIDTH = 16,          // 数据位宽
    parameter SHIFT_BITS = 4       // 移位控制位数
)(
    input [WIDTH-1:0] data_in,
    input [SHIFT_BITS-1:0] shift_amount,
    output [WIDTH-1:0] data_out
);
    // 内部连线，存储每级移位的中间结果
    wire [WIDTH-1:0] shift_stage [SHIFT_BITS:0];
    
    // 输入赋值给第一级
    assign shift_stage[0] = data_in;
    
    // 生成移位级联网络
    genvar i;
    generate
        for (i = 0; i < SHIFT_BITS; i = i + 1) begin : shifter_stage
            // 当前级的移位值为 2^i
            assign shift_stage[i+1] = shift_amount[i] ? 
                {{(2**i){1'b0}}, shift_stage[i][WIDTH-1:(2**i)]} : 
                shift_stage[i];
        end
    endgenerate
    
    // 输出结果为最后一级的输出
    assign data_out = shift_stage[SHIFT_BITS];
endmodule