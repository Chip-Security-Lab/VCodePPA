//SystemVerilog
module adaptive_clock_gate (
    input  wire       clk_in,
    input  wire [7:0] activity_level,
    input  wire       rst_n,
    output wire       clk_out
);
    reg gate_enable;
    
    // 优化比较逻辑 - 使用阈值常量并简化条件判断
    localparam ACTIVITY_THRESHOLD = 8'd10;
    wire activity_above_threshold;
    
    // 使用单比特比较结果而非完整的8位比较
    assign activity_above_threshold = (activity_level[7:4] != 0) || 
                                     (activity_level[3:0] > 4'd10);
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            gate_enable <= 1'b0;
        else
            gate_enable <= activity_above_threshold;
    end
    
    // 使用AND门实现时钟门控
    assign clk_out = clk_in & gate_enable;
endmodule