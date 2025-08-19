//SystemVerilog
module Masked_XNOR(
    input wire clk,          // 时钟信号用于流水线
    input wire rst_n,        // 复位信号
    input wire en_mask,
    input wire [3:0] mask,
    input wire [3:0] data,
    output wire [3:0] res
);
    // 直接计算组合逻辑结果，无需输入寄存器
    wire [3:0] and_path_direct = data & mask;       // 数据路径1：按位与
    wire [3:0] nand_path_direct = ~data & ~mask;    // 数据路径2：反码按位与
    
    // 组合逻辑后的首级流水线寄存器(前向重定时)
    reg [3:0] and_path_r, nand_path_r;
    reg [3:0] data_bypass_r;  // 用于bypass路径
    reg en_mask_r;
    
    // 流水线阶段1：重新定位的寄存器(移到组合逻辑后)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_path_r <= 4'b0;
            nand_path_r <= 4'b0;
            data_bypass_r <= 4'b0;
            en_mask_r <= 1'b0;
        end else begin
            and_path_r <= and_path_direct;
            nand_path_r <= nand_path_direct;
            data_bypass_r <= data;  // 直通路径存储原始数据
            en_mask_r <= en_mask;
        end
    end
    
    // 流水线阶段2：输出选择逻辑
    reg [3:0] result_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_r <= 4'b0;
        end else begin
            result_r <= en_mask_r ? (and_path_r | nand_path_r) : data_bypass_r;
        end
    end
    
    // 输出赋值
    assign res = result_r;
    
endmodule