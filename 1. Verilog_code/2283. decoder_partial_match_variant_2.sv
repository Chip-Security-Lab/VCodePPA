//SystemVerilog
`timescale 1ns / 1ps
module decoder_partial_match #(
    parameter MASK = 4'hF
) (
    input wire clk,          // 时钟信号，用于流水线寄存器
    input wire rst_n,        // 复位信号，低电平有效
    input wire [3:0] addr_in,
    output reg [7:0] device_sel
);
    // 内部信号定义 - 用于构建清晰的数据流路径
    reg [3:0] addr_masked_stage1;
    reg addr_match_stage2;
    
    // 第一流水线级：地址掩码操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_masked_stage1 <= 4'h0;
        end else begin
            addr_masked_stage1 <= addr_in & MASK;
        end
    end
    
    // 第二流水线级：地址比较操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_match_stage2 <= 1'b0;
        end else begin
            addr_match_stage2 <= (addr_masked_stage1 == 4'hA);
        end
    end
    
    // 第三流水线级：输出译码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_sel <= 8'h00;
        end else begin
            device_sel <= addr_match_stage2 ? 8'h01 : 8'h00;
        end
    end
    
endmodule