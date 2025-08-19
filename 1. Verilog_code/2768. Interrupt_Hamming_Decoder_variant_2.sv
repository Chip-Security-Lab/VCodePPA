//SystemVerilog
// 顶层模块
module Interrupt_Hamming_Decoder(
    input clk,
    input [7:0] code_in,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    wire [3:0] decoded_data;
    wire [1:0] error_status;
    
    // 实例化汉明解码器
    Hamming_Decoder decoder_inst (
        .code(code_in),
        .data(decoded_data),
        .error_status(error_status)
    );
    
    // 实例化中断控制器
    Interrupt_Controller irq_ctrl_inst (
        .clk(clk),
        .error_status(error_status),
        .decoded_data(decoded_data),
        .data_out(data_out),
        .uncorrectable_irq(uncorrectable_irq)
    );
endmodule

// 汉明解码器子模块
module Hamming_Decoder(
    input [7:0] code,
    output [3:0] data,
    output [1:0] error_status
);
    wire parity_check;
    wire parity_check1;
    wire parity_check2;
    
    // 汉明码解码器的核心逻辑
    // 全局奇偶校验
    assign parity_check = ^code;
    
    // 校验位1校验
    assign parity_check1 = code[7] ^ code[6] ^ code[5] ^ code[4] ^ code[0];
    
    // 校验位2校验
    assign parity_check2 = code[7] ^ code[6] ^ code[3] ^ code[2] ^ code[1];
    
    // 错误状态检测
    Error_Detector error_det_inst (
        .parity_check(parity_check),
        .parity_check1(parity_check1),
        .parity_check2(parity_check2),
        .error_status(error_status)
    );
    
    // 直接提取数据
    assign data = code[7:4];
endmodule

// 错误检测子模块
module Error_Detector(
    input parity_check,
    input parity_check1,
    input parity_check2,
    output reg [1:0] error_status
);
    always @(*) begin
        if (parity_check == 0) begin
            error_status = 2'b00; // 无错误
        end else begin
            if (parity_check1 != 0)
                error_status = 2'b01; // 1位错误
            else if (parity_check2 != 0)
                error_status = 2'b10; // 1位错误
            else
                error_status = 2'b11; // 不可纠正错误
        end
    end
endmodule

// 中断控制器子模块
module Interrupt_Controller(
    input clk,
    input [1:0] error_status,
    input [3:0] decoded_data,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    always @(posedge clk) begin
        data_out <= decoded_data;
        uncorrectable_irq <= (error_status == 2'b11);
    end
endmodule