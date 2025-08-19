//SystemVerilog
module hybrid_reset_counter (
    input wire clk,
    input wire async_rst,
    input wire sync_clear,
    input wire data_valid_in,  // 输入数据有效信号
    output wire data_valid_out, // 输出数据有效信号
    output wire [3:0] data_out
);

    // 流水线阶段寄存器
    reg [3:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2;
    
    // 阶段1: 输入和初始处理 - 使用case语句结构
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            data_stage1 <= 4'b1000;
            valid_stage1 <= 1'b0;
        end
        else begin
            // 提取控制条件
            case ({sync_clear, data_valid_in})
                2'b10: begin  // sync_clear=1, data_valid_in=0
                    data_stage1 <= 4'b0001;
                    valid_stage1 <= data_valid_in;
                end
                2'b11: begin  // sync_clear=1, data_valid_in=1
                    data_stage1 <= 4'b0001;
                    valid_stage1 <= data_valid_in;
                end
                2'b01: begin  // sync_clear=0, data_valid_in=1
                    data_stage1 <= {data_out[0], data_out[3:1]};
                    valid_stage1 <= 1'b1;
                end
                2'b00: begin  // sync_clear=0, data_valid_in=0
                    data_stage1 <= data_stage1;
                    valid_stage1 <= 1'b0;
                end
                default: begin
                    data_stage1 <= data_stage1;
                    valid_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 阶段2: 中间处理阶段 - 使用case语句结构
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            data_stage2 <= 4'b1000;
            valid_stage2 <= 1'b0;
        end
        else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出分配
    assign data_out = data_stage2;
    assign data_valid_out = valid_stage2;

endmodule