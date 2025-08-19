//SystemVerilog
module enabled_ring_counter (
    input  wire       clock,    // 系统时钟
    input  wire       reset,    // 异步复位信号
    input  wire       enable,   // 计数使能信号
    output reg  [3:0] count     // 环形计数器输出
);

    // 内部信号声明
    reg enable_r;                // 使能信号寄存器级

    // 第一级流水：捕获使能信号，避免使能信号成为关键路径
    always @(posedge clock or posedge reset) begin
        if (reset)
            enable_r <= 1'b0;
        else
            enable_r <= enable;
    end
    
    // 更新计数器状态 - 直接计算，减少组合逻辑路径
    always @(posedge clock or posedge reset) begin
        if (reset)
            count <= 4'b0001;
        else if (enable_r)
            // 优化：直接执行移位操作，避免中间寄存器
            count <= {count[2:0], count[3]};
    end

endmodule