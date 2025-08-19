//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module neg_edge_sync_reset_reg (
    input clk, rst,
    input [15:0] d_in,
    input load,
    output [15:0] q_out
);
    // 优化后的直接连接设计，减少了中间层的延迟
    reg [15:0] q_reg;
    
    // 负边沿触发的寄存器逻辑
    always @(negedge clk) begin
        if (rst)
            q_reg <= 16'h0000;  // 使用十六进制格式以减少位宽表示
        else if (load)
            q_reg <= d_in;
    end
    
    // 连续赋值输出
    assign q_out = q_reg;
endmodule

// 控制单元子模块 - 已优化成顶层直接逻辑
module control_unit (
    input clk, rst, load,
    output reset_signal,
    output load_enable
);
    // 控制信号直通，无延迟传递
    assign reset_signal = rst;
    assign load_enable = load;
endmodule

// 数据通路子模块 - 优化时序和资源利用
module data_path #(
    parameter WIDTH = 16
)(
    input clk,
    input reset_signal,
    input load_enable,
    input [WIDTH-1:0] d_in,
    output reg [WIDTH-1:0] q_out
);
    // 优化后的寄存器逻辑，采用非阻塞赋值确保正确的时序行为
    always @(negedge clk) begin
        if (reset_signal)
            q_out <= {WIDTH{1'b0}};
        else if (load_enable)
            q_out <= d_in;
    end
endmodule