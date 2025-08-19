//SystemVerilog
module delayed_write_buffer (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire [15:0] data_in,
    input wire trigger,
    input wire ready_in,  // 输入准备信号
    output wire ready_out, // 输出准备信号
    output wire valid_out, // 输出有效信号
    output reg [15:0] data_out
);
    // 流水线阶段1: 数据缓存和状态检测
    reg [15:0] buffer_stage1;
    reg write_pending_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 输出准备
    reg [15:0] buffer_stage2;
    reg write_pending_stage2;
    reg valid_stage2;
    
    // 流水线控制信号
    wire stage1_ready;
    wire stage2_ready;
    
    // 流水线控制逻辑
    assign stage2_ready = ready_in || !valid_stage2;
    assign stage1_ready = stage2_ready || !valid_stage1;
    assign ready_out = stage1_ready;
    assign valid_out = valid_stage2 && !write_pending_stage2;
    
    // 流水线阶段1: 数据捕获和状态更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage1 <= 16'h0000;
            write_pending_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (stage1_ready) begin
            if (trigger) begin
                buffer_stage1 <= data_in;
                write_pending_stage1 <= 1'b1;
                valid_stage1 <= 1'b1;
            end else if (write_pending_stage1) begin
                write_pending_stage1 <= 1'b0;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段2: 输出处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage2 <= 16'h0000;
            write_pending_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (stage2_ready) begin
            buffer_stage2 <= buffer_stage1;
            write_pending_stage2 <= write_pending_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'h0000;
        end else if (valid_stage2 && !write_pending_stage2 && ready_in) begin
            data_out <= buffer_stage2;
        end
    end
endmodule