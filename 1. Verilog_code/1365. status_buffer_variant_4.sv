//SystemVerilog
module status_buffer (
    input wire clk,
    input wire rst_n,              // 添加异步复位信号
    input wire [7:0] status_in,
    input wire valid,
    input wire ready,
    output reg [7:0] status_out,
    output reg out_valid
);
    // 流水线阶段1: 输入寄存
    reg [7:0] status_in_stage1;
    reg valid_stage1;
    reg ready_stage1;
    reg out_valid_stage1;
    
    // 流水线阶段2: 状态计算
    reg [7:0] computed_status_stage2;
    reg valid_stage2;
    
    // 流水线阶段3: 输出缓冲
    reg [7:0] next_status_out;
    reg next_out_valid;
    
    // 阶段1: 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_in_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b0;
            out_valid_stage1 <= 1'b0;
        end else begin
            status_in_stage1 <= status_in;
            valid_stage1 <= valid;
            ready_stage1 <= ready;
            out_valid_stage1 <= out_valid;
        end
    end
    
    // 阶段2: 状态计算 - 预先计算所有可能的状态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            computed_status_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            case ({valid_stage1, ready_stage1, out_valid_stage1})
                3'b000, 3'b001, 3'b010: begin  // 保持当前状态场景
                    computed_status_stage2 <= status_out;
                    valid_stage2 <= out_valid;
                end
                3'b011: begin  // 清除状态场景
                    computed_status_stage2 <= 8'b0;
                    valid_stage2 <= 1'b0;
                end
                3'b100, 3'b110: begin  // 更新状态场景
                    computed_status_stage2 <= status_out | status_in_stage1;
                    valid_stage2 <= 1'b1;
                end
                3'b101: begin  // 保持当前状态场景
                    computed_status_stage2 <= status_out;
                    valid_stage2 <= out_valid;
                end
                3'b111: begin  // 清除状态场景
                    computed_status_stage2 <= 8'b0;
                    valid_stage2 <= 1'b0;
                end
            endcase
        end
    end
    
    // 阶段3: 输出缓冲 - 更新最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_out <= 8'b0;
            out_valid <= 1'b0;
        end else begin
            status_out <= computed_status_stage2;
            out_valid <= valid_stage2;
        end
    end
    
endmodule