//SystemVerilog
// 顶层模块：管理奇偶校验配置和子模块连接
module configurable_parity #(
    parameter WIDTH = 16
)(
    input clk,
    input cfg_parity_type, // 0: even, 1: odd
    input [WIDTH-1:0] data,
    output parity
);
    // 内部连线
    wire calculated_parity;
    
    // 子模块实例化
    parity_calculator #(
        .WIDTH(WIDTH)
    ) calc_inst (
        .data(data),
        .parity(calculated_parity)
    );
    
    parity_adjuster adj_inst (
        .clk(clk),
        .raw_parity(calculated_parity),
        .parity_type(cfg_parity_type),
        .adjusted_parity(parity)
    );
    
endmodule

// 子模块1：计算原始奇偶校验位
module parity_calculator #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data,
    output parity
);
    assign parity = ^data;
endmodule

// 子模块2：根据配置调整奇偶校验位
module parity_adjuster (
    input clk,
    input raw_parity,
    input parity_type, // 0: even, 1: odd
    output reg adjusted_parity
);
    // 寄存最终奇偶校验结果
    always @(posedge clk) begin
        if (parity_type == 1'b1) begin
            adjusted_parity <= raw_parity;
        end else begin
            adjusted_parity <= ~raw_parity;
        end
    end
endmodule