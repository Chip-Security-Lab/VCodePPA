//SystemVerilog
module eth_fcs_gen (
    input wire clk,
    input wire rst_n,
    input wire sof,
    input wire data_valid,
    input wire [7:0] data,
    output reg [31:0] fcs,
    output reg fcs_valid
);

    // 优化的流水线寄存器
    reg [7:0] data_stage1, data_stage2;
    reg [31:0] fcs_stage1, fcs_stage2;
    reg valid_stage1, valid_stage2;
    reg sof_stage1, sof_stage2;
    
    // 优化的中间结果寄存器
    reg [31:0] fcs_next_stage1, fcs_next_stage2;
    
    // CRC计算优化常量 - 提前计算的位映射
    localparam [31:0] CRC_INIT = 32'hFFFFFFFF;
    
    // 第一级流水线 - 优化的位操作逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'h0;
            fcs_stage1 <= 32'h0;
            valid_stage1 <= 1'b0;
            sof_stage1 <= 1'b0;
            fcs_next_stage1 <= 32'h0;
        end else begin
            data_stage1 <= data;
            valid_stage1 <= data_valid;
            sof_stage1 <= sof;
            
            if (sof) begin
                fcs_stage1 <= CRC_INIT;
                fcs_next_stage1 <= CRC_INIT;
            end else if (data_valid) begin
                fcs_stage1 <= fcs;
                
                // 优化的第一部分CRC计算 - 批量异或操作
                for (int i = 0; i < 8; i++) begin
                    fcs_next_stage1[i] <= fcs[i+24] ^ data[i] ^ fcs[i];
                end
                
                for (int i = 0; i < 8; i++) begin
                    fcs_next_stage1[i+8] <= fcs[i] ^ fcs[i+24] ^ data[i] ^ fcs[i+8];
                end
                
                // 保持高16位不变，留给第二阶段处理
                fcs_next_stage1[31:16] <= fcs_next_stage1[31:16];
            end
        end
    end

    // 第二级流水线 - 优化的比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'h0;
            fcs_stage2 <= 32'h0;
            valid_stage2 <= 1'b0;
            sof_stage2 <= 1'b0;
            fcs_next_stage2 <= 32'h0;
        end else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            sof_stage2 <= sof_stage1;
            fcs_stage2 <= fcs_stage1;
            
            if (sof_stage1) begin
                fcs_next_stage2 <= fcs_next_stage1;
            end else if (valid_stage1) begin
                // 保留前16位计算结果
                fcs_next_stage2[15:0] <= fcs_next_stage1[15:0];
                
                // 优化的后16位CRC计算 - 分组处理提高并行性
                for (int i = 0; i < 8; i++) begin
                    fcs_next_stage2[i+16] <= fcs_stage1[i+8] ^ fcs_stage1[i+24] ^ data_stage1[i] ^ fcs_stage1[i+16];
                end
                
                // 批处理最后8位计算
                for (int i = 0; i < 8; i++) begin
                    fcs_next_stage2[i+24] <= fcs_stage1[i+16] ^ fcs_stage1[i+24];
                end
            end
        end
    end

    // 优化的输出级 - 使用条件赋值减少MUX层级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fcs <= 32'h0;
            fcs_valid <= 1'b0;
        end else begin
            fcs <= sof_stage2 ? CRC_INIT : (valid_stage2 ? fcs_next_stage2 : fcs);
            fcs_valid <= valid_stage2;
        end
    end

endmodule