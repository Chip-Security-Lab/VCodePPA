//SystemVerilog
module adaptive_clock_gate (
    input  wire        clk_in,
    input  wire        rst_n,
    // Valid-Ready接口信号
    input  wire        valid_in,
    input  wire [7:0]  activity_level,
    output wire        ready_out,
    output wire        clk_out
);
    // 内部信号
    reg gate_enable;
    reg activity_valid;
    reg activity_threshold_met;
    
    // 活动阈值检测 - 预计算以减少关键路径
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            activity_threshold_met <= 1'b0;
        else
            activity_threshold_met <= (activity_level > 8'd10);
    end
    
    // Ready信号逻辑 - 恒为高，降低路径复杂度
    assign ready_out = 1'b1;
    
    // 握手完成信号 - 简化组合逻辑路径
    wire handshake_done = valid_in; // 由于ready_out恒为1，简化表达式
    
    // 活动电平有效性寄存
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            activity_valid <= 1'b0;
        else if (handshake_done)
            activity_valid <= 1'b1;
    end
    
    // 时钟门控逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            gate_enable <= 1'b0;
        else if (handshake_done)
            gate_enable <= activity_threshold_met;
    end
    
    // 专用时钟门控单元
    wire gated_clock;
    assign gated_clock = clk_in & gate_enable;
    
    // 输出时钟
    assign clk_out = gated_clock;
endmodule