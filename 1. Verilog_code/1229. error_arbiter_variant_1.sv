//SystemVerilog
///////////////////////////////////////////////////////////
// Module: error_arbiter_top
// Description: 顶层模块，处理错误仲裁功能
///////////////////////////////////////////////////////////
module error_arbiter_top #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    input wire error_en,
    output wire [WIDTH-1:0] grant_o
);
    // 内部信号
    wire [WIDTH-1:0] req_reg;
    wire error_en_reg;
    wire [WIDTH-1:0] normal_grant;

    // 输入寄存器子模块
    input_register #(
        .WIDTH(WIDTH)
    ) u_input_register (
        .clk(clk),
        .rst_n(rst_n),
        .req_i(req_i),
        .error_en(error_en),
        .req_o(req_reg),
        .error_en_o(error_en_reg)
    );

    // 仲裁逻辑子模块
    priority_encoder #(
        .WIDTH(WIDTH)
    ) u_priority_encoder (
        .req_i(req_reg),
        .grant_o(normal_grant)
    );

    // 输出逻辑子模块
    output_controller #(
        .WIDTH(WIDTH)
    ) u_output_controller (
        .clk(clk),
        .rst_n(rst_n),
        .normal_grant(normal_grant),
        .error_en(error_en_reg),
        .grant_o(grant_o)
    );

endmodule

///////////////////////////////////////////////////////////
// Module: input_register
// Description: 输入信号同步和寄存器
///////////////////////////////////////////////////////////
module input_register #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    input wire error_en,
    output reg [WIDTH-1:0] req_o,
    output reg error_en_o
);
    // 输入寄存器处理
    always @(posedge clk) begin
        if (!rst_n) begin
            req_o <= {WIDTH{1'b0}};
            error_en_o <= 1'b0;
        end else begin
            req_o <= req_i;
            error_en_o <= error_en;
        end
    end
endmodule

///////////////////////////////////////////////////////////
// Module: priority_encoder
// Description: 优先级编码器，实现"req & (~req + 1)"操作
///////////////////////////////////////////////////////////
module priority_encoder #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] req_i,
    output wire [WIDTH-1:0] grant_o
);
    // 优先级编码逻辑 - 采用最右边的请求信号
    assign grant_o = req_i & (~req_i + 1);
endmodule

///////////////////////////////////////////////////////////
// Module: output_controller
// Description: 输出控制逻辑，处理正常授权和错误模式
///////////////////////////////////////////////////////////
module output_controller #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] normal_grant,
    input wire error_en,
    output reg [WIDTH-1:0] grant_o
);
    // 输出寄存器处理
    always @(posedge clk) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= error_en ? {WIDTH{1'b1}} : normal_grant;
        end
    end
endmodule