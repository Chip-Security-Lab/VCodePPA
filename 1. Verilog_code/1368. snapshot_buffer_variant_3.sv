//SystemVerilog
module snapshot_buffer (
    input wire clk,
    input wire rst_n,    // 添加异步复位信号
    input wire [31:0] live_data,
    input wire capture,
    output reg [31:0] snapshot_data
);
    // 内部流水线寄存器
    reg capture_stage1, capture_stage2;
    reg [31:0] live_data_stage1, live_data_stage2;
    reg data_changed;
    
    // 第一级流水线：寄存数据和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture_stage1 <= 1'b0;
            live_data_stage1 <= 32'h0;
        end else begin
            capture_stage1 <= capture;
            live_data_stage1 <= live_data;
        end
    end
    
    // 第二级流水线：计算数据是否变化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture_stage2 <= 1'b0;
            live_data_stage2 <= 32'h0;
            data_changed <= 1'b0;
        end else begin
            capture_stage2 <= capture_stage1;
            live_data_stage2 <= live_data_stage1;
            data_changed <= (live_data_stage1 != snapshot_data);
        end
    end
    
    // 第三级流水线：根据条件更新输出数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            snapshot_data <= 32'h0;
        end else if (capture_stage2 && data_changed) begin
            snapshot_data <= live_data_stage2;
        end
    end
    
endmodule