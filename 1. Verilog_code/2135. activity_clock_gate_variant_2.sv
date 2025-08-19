//SystemVerilog
module activity_clock_gate (
    input  wire clk_in,
    input  wire [7:0] data_in,
    input  wire [7:0] prev_data,
    output wire clk_out
);
    // 使用直接的位比较代替异或后求或，减少逻辑层级
    // 数据变化检测逻辑
    wire activity_detected;
    
    // 优化布尔表达式：直接检测数据是否相等
    assign activity_detected = (data_in != prev_data);
    
    // 时钟门控逻辑
    assign clk_out = clk_in & activity_detected;
endmodule