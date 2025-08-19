//SystemVerilog
module parity_checker_sync_reg (
    input clk, rst_n,
    input [15:0] data,
    input data_valid,
    output reg parity,
    output reg parity_valid
);
    // 第一级流水线 - 将16位数据分成两部分计算
    reg [7:0] data_stage1_upper, data_stage1_lower;
    reg valid_stage1;
    
    // 第二级流水线 - 存储第一级计算的部分奇偶校验结果
    reg parity_stage2_upper, parity_stage2_lower;
    reg valid_stage2;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1_upper <= 8'b0;
            data_stage1_lower <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1_upper <= data[15:8];
            data_stage1_lower <= data[7:0];
            valid_stage1 <= data_valid;
        end
    end
    
    // 第二级流水线寄存器 - 计算各部分的奇偶校验
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_stage2_upper <= 1'b0;
            parity_stage2_lower <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            parity_stage2_upper <= ~^data_stage1_upper; // 上半部分偶校验
            parity_stage2_lower <= ~^data_stage1_lower; // 下半部分偶校验
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级 - 合并两部分奇偶校验结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity <= 1'b0;
            parity_valid <= 1'b0;
        end else begin
            parity <= parity_stage2_upper ^ parity_stage2_lower; // 合并结果
            parity_valid <= valid_stage2;
        end
    end
endmodule