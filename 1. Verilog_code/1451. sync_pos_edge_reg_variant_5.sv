//SystemVerilog
module sync_pos_edge_reg(
    input clk, rst_n,
    input [7:0] data_in,
    input load_en,
    output [7:0] data_out
);
    // 内部寄存器声明
    reg [7:0] data_reg;
    
    // 组合逻辑模块实例化
    comb_logic comb_inst(
        .data_in(data_in),
        .load_en(load_en),
        .data_to_reg(data_to_reg)
    );
    
    // 时序逻辑部分 - 寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 8'b0;
        else
            data_reg <= data_to_reg;
    end
    
    // 组合逻辑部分 - 输出赋值
    assign data_out = data_reg;
    
    // 内部连线声明
    wire [7:0] data_to_reg;
    
endmodule

// 组合逻辑模块
module comb_logic(
    input [7:0] data_in,
    input load_en,
    output [7:0] data_to_reg
);
    // 组合逻辑实现
    assign data_to_reg = load_en ? data_in : 8'b0;
    
endmodule