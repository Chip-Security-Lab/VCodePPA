//SystemVerilog
// 顶层模块
module sync_rotate_right_shifter (
    input              clk_i,
    input              arst_n,  // Active low async reset
    input      [31:0]  data_i,
    input      [4:0]   shift_i,
    output     [31:0]  data_o
);
    // 内部连线
    wire [31:0] rotated_data;
    
    // 实例化旋转逻辑子模块
    rotate_logic u_rotate_logic (
        .data_i     (data_i),
        .shift_i    (shift_i),
        .rotated_o  (rotated_data)
    );
    
    // 实例化寄存器子模块
    output_register u_output_register (
        .clk_i      (clk_i),
        .arst_n     (arst_n),
        .data_i     (rotated_data),
        .data_o     (data_o)
    );
    
endmodule

// 旋转逻辑子模块 - 纯组合逻辑
module rotate_logic (
    input      [31:0] data_i,
    input      [4:0]  shift_i,
    output     [31:0] rotated_o
);
    // 参数化设计，提高灵活性
    parameter DATA_WIDTH = 32;
    
    // 优化的旋转实现，使用移位操作
    assign rotated_o = {data_i, data_i} >> shift_i;
    
endmodule

// 输出寄存器子模块 - 时序逻辑
module output_register (
    input              clk_i,
    input              arst_n,
    input      [31:0]  data_i,
    output reg [31:0]  data_o
);
    // 参数化设计
    parameter DATA_WIDTH = 32;
    parameter RESET_VALUE = {DATA_WIDTH{1'b0}};
    
    // 同步更新，异步复位
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n)
            data_o <= RESET_VALUE;
        else
            data_o <= data_i;
    end
    
endmodule