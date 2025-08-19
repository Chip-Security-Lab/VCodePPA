//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module sync_buffer_async_rst (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg [7:0] data_out
);

    // 增加流水线级数，将数据处理分为三级
    reg [7:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2;
    reg ready_stage1, ready_stage2, ready_stage3;

    // 第一级流水线 - 数据接收和缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b1;
        end else begin
            // 使用{valid_in,ready_stage1,ready_stage2}作为case条件
            case ({valid_in, ready_stage1, ready_stage2})
                3'b110: begin  // 有效数据输入且准备好接收
                    data_stage1 <= data_in;
                    valid_stage1 <= 1'b1;
                end
                3'b??1: begin  // 下一级准备好接收
                    valid_stage1 <= 1'b0;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
            
            // 更新ready状态
            ready_stage1 <= !valid_stage1 || ready_stage2;
        end
    end

    // 第二级流水线 - 数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
            ready_stage2 <= 1'b1;
        end else begin
            // 使用{valid_stage1,ready_stage2,ready_stage3}作为case条件
            case ({valid_stage1, ready_stage2, ready_stage3})
                3'b110: begin  // 有效数据输入且准备好接收
                    data_stage2 <= data_stage1;
                    valid_stage2 <= 1'b1;
                end
                3'b??1: begin  // 下一级准备好接收
                    valid_stage2 <= 1'b0;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
            
            // 更新ready状态
            ready_stage2 <= !valid_stage2 || ready_stage3;
        end
    end

    // 第三级流水线 - 数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            ready_stage3 <= 1'b1;
        end else begin
            // 使用{valid_stage2,ready_stage3}作为case条件
            case ({valid_stage2, ready_stage3})
                2'b11: begin  // 有效数据输入且准备好接收
                    data_out <= data_stage2;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
            
            // 最后阶段总是准备好接收新数据
            ready_stage3 <= 1'b1;
        end
    end

    // 输出ready信号
    assign ready_out = ready_stage1;

endmodule