//SystemVerilog
module toggle_buffer (
    input wire clk,
    input wire toggle,
    input wire [15:0] data_in,
    input wire write_en,
    output wire [15:0] data_out
);
    reg [15:0] buffer_a, buffer_b;
    reg sel;
    reg sel_out; // Register for output selection to break critical path
    
    // 选择器逻辑
    always @(posedge clk) begin
        if (toggle)
            sel <= ~sel;
    end
    
    // 缓存输出选择信号以减少关键路径延迟
    always @(posedge clk) begin
        sel_out <= sel;
    end
    
    // 写入逻辑，简化条件判断结构
    always @(posedge clk) begin
        if (write_en && !sel)
            buffer_a <= data_in;
        if (write_en && sel)
            buffer_b <= data_in;
    end
    
    // 输出多路复用器 - 使用寄存的选择信号减少关键路径
    assign data_out = sel_out ? buffer_b : buffer_a;
endmodule