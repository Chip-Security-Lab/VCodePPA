//SystemVerilog
module bidir_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, en, dir, data_in,
    output wire [WIDTH-1:0] q_out
);
    reg [WIDTH-1:0] shiftreg;
    wire [WIDTH-1:0] next_shiftreg;
    
    // 组合逻辑部分 - 使用优化的移位逻辑
    shift_logic_opt #(.WIDTH(WIDTH)) shift_comb (
        .current_reg(shiftreg),
        .data_in(data_in),
        .en(en),
        .dir(dir),
        .next_reg(next_shiftreg)
    );
    
    // 时序逻辑部分 - 寄存器更新
    always @(posedge clk) begin
        if (rst)
            shiftreg <= {WIDTH{1'b0}};
        else
            shiftreg <= next_shiftreg;
    end
    
    // 输出赋值
    assign q_out = shiftreg;
endmodule

// 优化的组合逻辑模块 - 使用条件选择逻辑
module shift_logic_opt #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] current_reg,
    input wire data_in, en, dir,
    output wire [WIDTH-1:0] next_reg
);
    // 左移和右移结果
    wire [WIDTH-1:0] left_shift = {current_reg[WIDTH-2:0], data_in};
    wire [WIDTH-1:0] right_shift = {data_in, current_reg[WIDTH-1:1]};
    
    // 使用条件选择逻辑（类似于条件反相技术）
    assign next_reg = en ? (dir ? left_shift : right_shift) : current_reg;
endmodule