//SystemVerilog
module pl_reg_init #(parameter W=8, INIT=0) (
    input clk, init,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);
    // 内部信号声明
    reg [W-1:0] data_out_reg;
    wire [W-1:0] next_data;
    
    // 组合逻辑部分 - 独立模块实例化
    pl_reg_init_comb #(
        .W(W),
        .INIT(INIT)
    ) comb_logic (
        .init(init),
        .data_in(data_in),
        .next_data(next_data)
    );
    
    // 时序逻辑部分 - 仅在时钟边沿触发
    always @(posedge clk)
        data_out_reg <= next_data;
        
    // 输出赋值
    assign data_out = data_out_reg;
endmodule

// 纯组合逻辑模块
module pl_reg_init_comb #(parameter W=8, INIT=0) (
    input init,
    input [W-1:0] data_in,
    output [W-1:0] next_data
);
    // 组合逻辑实现
    assign next_data = init ? INIT : data_in;
endmodule