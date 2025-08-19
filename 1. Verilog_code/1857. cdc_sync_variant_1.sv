//SystemVerilog
// 顶层模块
module cdc_sync #(parameter WIDTH=1) (
    input  wire             src_clk,   // 源时钟域
    input  wire             dst_clk,   // 目标时钟域
    input  wire             rst,       // 系统复位信号
    input  wire [WIDTH-1:0] async_in,  // 源时钟域输入信号
    output wire [WIDTH-1:0] sync_out   // 目标时钟域同步输出
);
    // 内部连线
    wire [WIDTH-1:0] src_captured;
    
    // 实例化源时钟域捕获模块
    src_domain_capture #(
        .WIDTH(WIDTH)
    ) src_stage (
        .clk       (src_clk),
        .rst       (rst),
        .async_in  (async_in),
        .captured  (src_captured)
    );
    
    // 实例化目标时钟域同步模块
    dst_domain_sync #(
        .WIDTH(WIDTH)
    ) dst_stage (
        .clk       (dst_clk),
        .rst       (rst),
        .src_data  (src_captured),
        .sync_out  (sync_out)
    );
    
endmodule

// 源时钟域捕获子模块
module src_domain_capture #(parameter WIDTH=1) (
    input  wire             clk,       // 源时钟
    input  wire             rst,       // 复位信号
    input  wire [WIDTH-1:0] async_in,  // 输入数据
    output reg  [WIDTH-1:0] captured   // 捕获的数据
);
    // 组合逻辑部分
    wire [WIDTH-1:0] next_captured;
    assign next_captured = async_in;
    
    // 时序逻辑部分
    always @(posedge clk or posedge rst) begin
        if (rst) 
            captured <= {WIDTH{1'b0}};
        else 
            captured <= next_captured;
    end
endmodule

// 目标时钟域同步子模块
module dst_domain_sync #(parameter WIDTH=1) (
    input  wire             clk,       // 目标时钟
    input  wire             rst,       // 复位信号
    input  wire [WIDTH-1:0] src_data,  // 来自源域的数据
    output wire [WIDTH-1:0] sync_out   // 同步后的输出
);
    // 内部寄存器
    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] sync_reg2;
    
    // 组合逻辑部分
    wire [WIDTH-1:0] next_sync_reg1;
    wire [WIDTH-1:0] next_sync_reg2;
    
    assign next_sync_reg1 = src_data;
    assign next_sync_reg2 = sync_reg1;
    assign sync_out = sync_reg2;
    
    // 时序逻辑部分
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_reg1 <= {WIDTH{1'b0}};
            sync_reg2 <= {WIDTH{1'b0}};
        end else begin
            sync_reg1 <= next_sync_reg1;
            sync_reg2 <= next_sync_reg2;
        end
    end
    
endmodule