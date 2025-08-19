//SystemVerilog
module Demux_Pipelined #(parameter DW=16, STAGES=2) (
    input clk,
    input rst_n,  // 添加复位信号
    input valid_in,  // 添加输入有效信号
    input [DW-1:0] data_in,
    input [$clog2(STAGES)-1:0] stage_sel,
    output reg [STAGES-1:0][DW-1:0] pipe_out,
    output reg [STAGES-1:0] valid_out  // 添加输出有效信号
);

    // 第一级流水线寄存器
    reg [DW-1:0] data_stage1;
    reg [$clog2(STAGES)-1:0] sel_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器 - 用于存储中间解码结果
    reg [STAGES-1:0] decoded_sel_stage2;
    reg [DW-1:0] data_stage2;
    reg valid_stage2;

    // 第一级流水线 - 注册输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            sel_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            sel_stage1 <= stage_sel;
            valid_stage1 <= valid_in;
        end
    end

    // 第二级流水线 - 解码选择信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_sel_stage2 <= 0;
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            decoded_sel_stage2 <= 0;  // 默认清零
            if (valid_stage1) begin
                decoded_sel_stage2[sel_stage1] <= 1'b1;  // 解码选择信号
            end
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第三级流水线 - 产生输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_out <= 0;
            valid_out <= 0;
        end else begin
            for (int i = 0; i < STAGES; i++) begin
                if (decoded_sel_stage2[i] && valid_stage2) begin
                    pipe_out[i] <= data_stage2;
                    valid_out[i] <= 1'b1;
                end else begin
                    valid_out[i] <= 1'b0;
                    // 保持pipe_out[i]的值不变，除非被更新
                end
            end
        end
    end

endmodule