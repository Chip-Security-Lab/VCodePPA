//SystemVerilog
// 顶层模块
module async_arbiter #(
    parameter WIDTH = 4
)(
    input  wire        clk_i,       // 时钟信号输入
    input  wire        rst_n_i,     // 异步复位信号，低电平有效
    input  wire [WIDTH-1:0] req_i,  // 请求信号输入
    output wire [WIDTH-1:0] grant_o // 授权信号输出
);
    // 内部连线
    wire [WIDTH-1:0] req_r;         // 请求寄存器输出
    wire [WIDTH-1:0] lowest_bit;    // 最低有效位信号
    wire [WIDTH-1:0] lowest_bit_r;  // 最低有效位寄存器输出

    // 请求信号寄存模块实例化
    request_register #(
        .WIDTH(WIDTH)
    ) req_reg_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .req_i(req_i),
        .req_o(req_r)
    );

    // 最低有效位检测模块实例化
    lowest_bit_detector #(
        .WIDTH(WIDTH)
    ) lbd_inst (
        .req_i(req_r),
        .lowest_bit_o(lowest_bit)
    );

    // 最低有效位寄存模块实例化
    lowest_bit_register #(
        .WIDTH(WIDTH)
    ) lb_reg_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .lowest_bit_i(lowest_bit),
        .lowest_bit_o(lowest_bit_r)
    );

    // 授权信号生成模块实例化
    grant_generator #(
        .WIDTH(WIDTH)
    ) grant_gen_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .req_i(req_r),
        .lowest_bit_i(lowest_bit_r),
        .grant_o(grant_o)
    );
endmodule

// 请求信号寄存子模块 - 第一级流水线
module request_register #(
    parameter WIDTH = 4
)(
    input  wire        clk_i,         // 时钟信号输入
    input  wire        rst_n_i,       // 异步复位信号，低电平有效
    input  wire [WIDTH-1:0] req_i,    // 请求信号输入
    output reg  [WIDTH-1:0] req_o     // 寄存后的请求信号输出
);
    // 第一级流水线：寄存请求信号
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            req_o <= {WIDTH{1'b0}};
        end else begin
            req_o <= req_i;
        end
    end
endmodule

// 最低有效位检测子模块 - 组合逻辑
module lowest_bit_detector #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] req_i,         // 请求信号输入
    output wire [WIDTH-1:0] lowest_bit_o   // 最低有效位输出
);
    // 隔离最低的'1'位 (isolate lowest one bit)
    assign lowest_bit_o = req_i & (~req_i + 1);
endmodule

// 最低有效位寄存子模块 - 第二级流水线
module lowest_bit_register #(
    parameter WIDTH = 4
)(
    input  wire        clk_i,              // 时钟信号输入
    input  wire        rst_n_i,            // 异步复位信号，低电平有效
    input  wire [WIDTH-1:0] lowest_bit_i,  // 最低有效位输入
    output reg  [WIDTH-1:0] lowest_bit_o   // 寄存后的最低有效位输出
);
    // 第二级流水线：寄存最低有效位结果
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            lowest_bit_o <= {WIDTH{1'b0}};
        end else begin
            lowest_bit_o <= lowest_bit_i;
        end
    end
endmodule

// 授权信号生成子模块 - 第三级流水线
module grant_generator #(
    parameter WIDTH = 4
)(
    input  wire        clk_i,              // 时钟信号输入
    input  wire        rst_n_i,            // 异步复位信号，低电平有效
    input  wire [WIDTH-1:0] req_i,         // 请求信号输入
    input  wire [WIDTH-1:0] lowest_bit_i,  // 最低有效位输入
    output reg  [WIDTH-1:0] grant_o        // 授权信号输出
);
    // 第三级流水线：生成最终授权信号
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= lowest_bit_i & req_i;
        end
    end
endmodule