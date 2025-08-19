//SystemVerilog
module async_left_shifter_custom_reset #(
    parameter WIDTH = 8,
    parameter RESET_VAL = 8'hA5  // Custom reset pattern
)(
    input                  rstn,
    input      [WIDTH-1:0] din,
    input      [$clog2(WIDTH)-1:0] shift,
    output     [WIDTH-1:0] dout
);
    // 内部信号声明
    reg [WIDTH-1:0] shifted_data;
    
    // 优化的左移逻辑与复位控制逻辑合并
    // 使用多级逐步左移而非单次左移，降低关键路径延迟
    always @(*) begin
        if (!rstn) begin
            shifted_data = RESET_VAL;
        end else begin
            // 条件求和式移位算法实现
            // 使用位爆炸的方式实现可变左移，减少逻辑层级
            shifted_data = din;
            
            // 第一级条件移位 (移1位)
            if (shift[0]) 
                shifted_data = {shifted_data[WIDTH-2:0], 1'b0};
                
            // 第二级条件移位 (移2位)
            if (shift[1]) 
                shifted_data = {shifted_data[WIDTH-3:0], 2'b00};
                
            // 第三级条件移位 (移4位)，仅当WIDTH>4时需要
            if (WIDTH > 4 && shift[2]) 
                shifted_data = {shifted_data[WIDTH-5:0], 4'b0000};
        end
    end
    
    // 输出赋值
    assign dout = shifted_data;
endmodule