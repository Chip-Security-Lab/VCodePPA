//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module decoder_temp_aware #(parameter THRESHOLD=85) (
    input clk,
    input rst_n,               // 添加复位信号
    input valid_in,            // 输入有效信号
    input [7:0] temp,
    input [3:0] addr,
    output reg valid_out,      // 输出有效信号
    output reg [15:0] decoded
);

    // 流水线阶段1寄存器
    reg [7:0] temp_stage1;
    reg [3:0] addr_stage1;
    reg valid_stage1;
    reg temp_over_threshold_stage1;
    
    // 流水线阶段2寄存器
    reg [3:0] addr_stage2;
    reg valid_stage2;
    reg temp_over_threshold_stage2;
    
    // 解码中间结果寄存器 - 减少第三级流水线的组合逻辑路径
    reg [15:0] decoded_base_stage2;
    reg [15:0] decoded_masked_stage2;
    
    // 第一级流水线：温度比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_stage1 <= 8'h0;
            addr_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
            temp_over_threshold_stage1 <= 1'b0;
        end else begin
            temp_stage1 <= temp;
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
            // 分解温度比较操作以减少路径延迟
            temp_over_threshold_stage1 <= (temp > THRESHOLD);
        end
    end

    // 第二级流水线：提前计算解码基础值和掩码值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
            temp_over_threshold_stage2 <= 1'b0;
            decoded_base_stage2 <= 16'h0;
            decoded_masked_stage2 <= 16'h0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            temp_over_threshold_stage2 <= temp_over_threshold_stage1;
            
            // 预计算基础解码值和掩码解码值，减少第三级流水线的组合逻辑延迟
            decoded_base_stage2 <= (1'b1 << addr_stage1);
            decoded_masked_stage2 <= ((1'b1 << addr_stage1) & 16'h00FF);
        end
    end

    // 第三级流水线：选择最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 16'h0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
            if (valid_stage2) begin
                // 使用预计算的值，减轻组合逻辑复杂度
                decoded <= temp_over_threshold_stage2 ? decoded_masked_stage2 : decoded_base_stage2;
            end
        end
    end

endmodule