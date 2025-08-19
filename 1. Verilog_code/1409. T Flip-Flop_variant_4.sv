//SystemVerilog

// 顶层模块
module t_flip_flop (
    input  wire clk,
    input  wire t,
    output wire q
);
    // 内部连线
    wire toggle_out;
    wire ff_out;
    
    // 实例化子模块
    toggle_logic toggle_unit (
        .t_in(t),
        .q_in(ff_out),
        .toggle_out(toggle_out)
    );
    
    ff_storage storage_unit (
        .clk(clk),
        .d_in(toggle_out),
        .q_out(ff_out)
    );
    
    // 输出连接
    assign q = ff_out;
    
endmodule

// 判断逻辑子模块
module toggle_logic (
    input  wire t_in,
    input  wire q_in,
    output wire toggle_out
);
    // 根据t输入决定是否翻转
    assign toggle_out = t_in ? ~q_in : q_in;
    
endmodule

// 存储子模块
module ff_storage (
    input  wire clk,
    input  wire d_in,
    output reg  q_out
);
    // 存储逻辑
    always @(posedge clk) begin
        q_out <= d_in;
    end
    
endmodule