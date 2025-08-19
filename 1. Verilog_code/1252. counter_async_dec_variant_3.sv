//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module counter_async_dec #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire en,
    output wire [WIDTH-1:0] count
);
    // 内部连接信号
    wire [WIDTH-1:0] current_count;
    wire [WIDTH-1:0] next_count;
    
    // 时钟管理子模块
    clock_manager clock_mgr_inst (
        .clk_in(clk),
        .clk_out(clk_buffered)
    );
    
    // 计数器运算单元
    counter_arithmetic_unit #(
        .WIDTH(WIDTH)
    ) arithmetic_unit_inst (
        .current_count(current_count),
        .enable(en),
        .next_count(next_count)
    );
    
    // 计数器寄存器和复位单元
    counter_register_unit #(
        .WIDTH(WIDTH)
    ) register_unit_inst (
        .clk(clk_buffered),
        .rst(rst),
        .next_count(next_count),
        .current_count(current_count)
    );
    
    // 输出缓冲单元
    output_buffer_unit #(
        .WIDTH(WIDTH)
    ) output_buffer_inst (
        .clk(clk_buffered),
        .count_in(current_count),
        .count_out(count)
    );
    
endmodule

// 时钟管理子模块 - 处理时钟分配和缓冲
module clock_manager (
    input  wire clk_in,
    output wire clk_out
);
    // 时钟缓冲减少扇出
    (* keep = "true" *) wire clk_buf;
    
    // 简单缓冲时钟信号
    assign clk_buf = clk_in;
    assign clk_out = clk_buf;
    
endmodule

// 计数器运算单元 - 纯组合逻辑，计算下一个计数值
module counter_arithmetic_unit #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] current_count,
    input  wire enable,
    output wire [WIDTH-1:0] next_count
);
    // 输入缓冲以减少扇出负载
    (* keep = "true" *) wire [WIDTH-1:0] count_buf;
    assign count_buf = current_count;
    
    // 解码器：只在使能有效时递减，否则保持当前值
    assign next_count = enable ? count_buf - 1'b1 : count_buf;
    
endmodule

// 计数器寄存器单元 - 管理计数器状态存储和复位
module counter_register_unit #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] next_count,
    output reg  [WIDTH-1:0] current_count
);
    // 输入缓冲
    (* keep = "true" *) reg [WIDTH-1:0] next_count_buf;
    
    // 缓存下一个计数值
    always @(posedge clk) begin
        if (!rst)
            next_count_buf <= next_count;
    end
    
    // 异步复位逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) 
            current_count <= {WIDTH{1'b1}}; // 复位为全1
        else 
            current_count <= next_count_buf;
    end
    
endmodule

// 输出缓冲单元 - 保护输出并减少扇出负载
module output_buffer_unit #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire [WIDTH-1:0] count_in,
    output reg  [WIDTH-1:0] count_out
);
    // 注册输出以减少逻辑关键路径
    always @(posedge clk) begin
        count_out <= count_in;
    end
    
endmodule