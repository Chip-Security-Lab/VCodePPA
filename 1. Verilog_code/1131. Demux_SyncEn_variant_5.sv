//SystemVerilog
module Demux_SyncEn #(parameter DW=8, AW=3) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output reg [(1<<AW)-1:0][DW-1:0] data_out
);
    // 流水线第一级 - 地址解码
    reg [AW-1:0] addr_stage1;
    reg en_stage1;
    reg [DW-1:0] data_in_stage1;
    reg [(1<<AW)-1:0] one_hot_addr_stage1;
    
    // 流水线第二级 - 数据分发准备
    reg [(1<<AW)-1:0] one_hot_addr_stage2; 
    reg en_stage2;
    reg [DW-1:0] data_in_stage2;
    
    // 流水线第三级 - 输出寄存器
    reg [(1<<AW)-1:0][DW-1:0] data_next;

    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;

    // 第一级流水线 - 地址解码和寄存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            en_stage1 <= 0;
            data_in_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            en_stage1 <= en;
            data_in_stage1 <= data_in;
            valid_stage1 <= 1'b1; // 假设每个周期都有有效数据
        end
    end
    
    // 地址解码 - 组合逻辑部分
    always @(*) begin
        one_hot_addr_stage1 = 0;
        if (valid_stage1) begin
            case(addr_stage1)
                3'd0: one_hot_addr_stage1 = 8'b00000001;
                3'd1: one_hot_addr_stage1 = 8'b00000010;
                3'd2: one_hot_addr_stage1 = 8'b00000100;
                3'd3: one_hot_addr_stage1 = 8'b00001000;
                3'd4: one_hot_addr_stage1 = 8'b00010000;
                3'd5: one_hot_addr_stage1 = 8'b00100000;
                3'd6: one_hot_addr_stage1 = 8'b01000000;
                3'd7: one_hot_addr_stage1 = 8'b10000000;
                default: one_hot_addr_stage1 = 8'b00000000;
            endcase
        end
    end

    // 第二级流水线 - 寄存解码结果和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot_addr_stage2 <= 0;
            en_stage2 <= 0;
            data_in_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            one_hot_addr_stage2 <= one_hot_addr_stage1;
            en_stage2 <= en_stage1;
            data_in_stage2 <= data_in_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第二级流水线 - 数据分发准备
    integer i;
    always @(*) begin
        data_next = 0;
        if (valid_stage2) begin
            for (i = 0; i < (1<<AW); i = i + 1) begin
                if (one_hot_addr_stage2[i] && en_stage2) begin
                    data_next[i] = data_in_stage2;
                end
            end
        end
    end
    
    // 第三级流水线 - 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            valid_stage3 <= 0;
        end else begin
            data_out <= data_next;
            valid_stage3 <= valid_stage2;
        end
    end
endmodule