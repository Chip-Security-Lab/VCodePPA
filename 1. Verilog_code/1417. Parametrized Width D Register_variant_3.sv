//SystemVerilog
// 顶层模块
module param_d_register #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] q
);
    // 内部连线
    wire [WIDTH-1:0] data_to_reg;
    wire reset_signal;
    
    // 实例化重置控制子模块
    reset_controller #(
        .WIDTH(WIDTH)
    ) u_reset_controller (
        .rst_n(rst_n),
        .reset_out(reset_signal)
    );
    
    // 实例化数据传输子模块
    data_path #(
        .WIDTH(WIDTH)
    ) u_data_path (
        .clk(clk),
        .reset_signal(reset_signal),
        .d_in(d),
        .q_out(q)
    );
    
endmodule

// 重置控制子模块
module reset_controller #(
    parameter WIDTH = 8
) (
    input wire rst_n,
    output wire reset_out
);
    // 生成活跃低重置信号
    assign reset_out = !rst_n;
endmodule

// 数据传输子模块
module data_path #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire reset_signal,
    input wire [WIDTH-1:0] d_in,
    output reg [WIDTH-1:0] q_out
);
    // 数据寄存器实现
    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal)
            q_out <= {WIDTH{1'b0}};
        else
            q_out <= d_in;
    end
endmodule