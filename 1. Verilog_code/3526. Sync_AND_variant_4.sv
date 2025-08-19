//SystemVerilog
module Sync_AND(
    input wire clk,
    input wire rst_n,
    
    // 数据输入接口
    input wire [7:0] signal_a,
    input wire [7:0] signal_b,
    input wire valid_in,
    output wire ready_out,
    
    // 数据输出接口
    output reg [7:0] reg_out,
    output reg valid_out,
    input wire ready_in
);

    // 流水线阶段定义
    // 第一级：数据捕获阶段
    reg [7:0] signal_a_stage1, signal_b_stage1;
    reg valid_stage1;
    
    // 第二级：计算阶段
    reg [7:0] result_stage2;
    reg valid_stage2;
    
    // 流水线控制信号
    wire stall_pipeline;
    
    // 当输出级阻塞且有效时，产生阻塞信号
    assign stall_pipeline = valid_out && !ready_in;
    
    // 只有当流水线未阻塞时，才接受新数据
    assign ready_out = !stall_pipeline;
    
    // 第一级流水线：数据捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_a_stage1 <= 8'b0;
            signal_b_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else if (!stall_pipeline) begin
            // 捕获输入数据
            signal_a_stage1 <= signal_a;
            signal_b_stage1 <= signal_b;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (!stall_pipeline) begin
            // 执行AND操作
            result_stage2 <= signal_a_stage1 & signal_b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级流水线：数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out <= 8'b0;
            valid_out <= 1'b0;
        end else if (!stall_pipeline) begin
            // 输出结果
            reg_out <= result_stage2;
            valid_out <= valid_stage2;
        end else if (ready_in) begin
            // 输出握手完成，清除有效位
            valid_out <= 1'b0;
        end
    end

endmodule