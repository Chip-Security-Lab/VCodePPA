//SystemVerilog
// 顶层模块 - 中断控制掩码系统
module int_ctrl_mask #(
    parameter DW = 16
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] req_in,
    input wire [DW-1:0] mask,
    output wire [DW-1:0] masked_req
);
    // 内部连接信号
    wire [DW-1:0] req_registered;
    wire [DW-1:0] mask_inverted;
    
    // 输入请求信号寄存子模块
    request_register #(
        .DW(DW)
    ) u_request_register (
        .clk(clk),
        .en(en),
        .req_in(req_in),
        .req_out(req_registered)
    );
    
    // 掩码处理子模块
    mask_processor #(
        .DW(DW)
    ) u_mask_processor (
        .clk(clk),
        .mask_in(mask),
        .inv_mask_out(mask_inverted)
    );
    
    // 掩码应用子模块
    mask_applicator #(
        .DW(DW)
    ) u_mask_applicator (
        .clk(clk),
        .request(req_registered),
        .mask(mask_inverted),
        .masked_output(masked_req)
    );
    
endmodule

// 子模块 - 请求信号寄存器
module request_register #(
    parameter DW = 16
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] req_in,
    output reg [DW-1:0] req_out
);
    always @(posedge clk) begin
        // 条件更新请求寄存器，减少多路选择器复杂度
        req_out <= en ? req_in : req_out;
    end
endmodule

// 子模块 - 掩码处理器
module mask_processor #(
    parameter DW = 16
)(
    input wire clk,
    input wire [DW-1:0] mask_in,
    output reg [DW-1:0] inv_mask_out
);
    always @(posedge clk) begin
        // 预计算掩码取反值，减少组合逻辑深度
        inv_mask_out <= ~mask_in;
    end
endmodule

// 子模块 - 掩码应用器
module mask_applicator #(
    parameter DW = 16
)(
    input wire clk,
    input wire [DW-1:0] request,
    input wire [DW-1:0] mask,
    output reg [DW-1:0] masked_output
);
    always @(posedge clk) begin
        // 应用掩码到请求信号
        masked_output <= request & mask;
    end
endmodule