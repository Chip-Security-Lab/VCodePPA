//SystemVerilog
module hybrid_reset_counter (
    input wire clk,
    input wire async_rst,
    input wire sync_clear,
    input wire enable,         // 添加启用信号用于流水线控制
    output wire [3:0] data_out
);

    // 流水线寄存器
    reg [3:0] stage1_data, stage2_data, stage3_data;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 合并所有具有相同触发条件的always块
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            // 重置所有阶段
            stage1_data <= 4'b1000;
            stage1_valid <= 1'b0;
            stage2_data <= 4'b0000;
            stage2_valid <= 1'b0;
            stage3_data <= 4'b0000;
            stage3_valid <= 1'b0;
        end
        else if (enable) begin
            // 第一阶段逻辑
            if (sync_clear) begin
                stage1_data <= 4'b0001;
                stage1_valid <= 1'b1;
            end
            else begin
                stage1_data <= {data_out[0], data_out[3:1]};
                stage1_valid <= 1'b1;
            end
            
            // 第二阶段逻辑：从第一阶段获取数据
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
            
            // 第三阶段逻辑：从第二阶段获取数据
            stage3_data <= stage2_data;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出逻辑：选择最终流水线阶段的数据
    assign data_out = stage3_data;
    
endmodule