//SystemVerilog
module activity_clock_gate (
    input  wire        clk_in,
    input  wire [7:0]  data_in,
    input  wire [7:0]  prev_data,
    output wire        clk_out
);
    // 第一级流水线：数据变化检测部分
    reg  [7:0] activity_bits_stage1;
    reg        activity_detected_stage1;
    reg  [7:0] data_in_reg, prev_data_reg;
    
    // 寄存数据输入，减少扇出负载
    always @(posedge clk_in) begin
        data_in_reg  <= data_in;
        prev_data_reg <= prev_data;
    end
    
    // 第一级流水线：计算数据变化位
    always @(posedge clk_in) begin
        activity_bits_stage1 <= data_in_reg ^ prev_data_reg;
    end
    
    // 第二级流水线：数据变化整合
    always @(posedge clk_in) begin
        activity_detected_stage1 <= |activity_bits_stage1;
    end
    
    // 时钟门控输出逻辑
    // 使用与门实现时钟门控，提高时钟树质量
    assign clk_out = clk_in & activity_detected_stage1;
    
    // 综合指示属性，告知工具保留时钟门控结构
    // synthesis attribute CLOCK_GATE_CELL of clk_out is true
    
endmodule