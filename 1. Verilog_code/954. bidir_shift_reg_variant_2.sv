//SystemVerilog
module bidir_shift_reg #(parameter W = 16) (
    input wire clock, reset,
    input wire direction,     // 0: right, 1: left
    input wire ser_in,
    output wire ser_out
);
    // 内部信号声明
    reg [W-1:0] register;
    wire [W-1:0] next_register;
    
    // 组合逻辑部分 - 计算下一个寄存器状态
    shift_logic #(.WIDTH(W)) shift_comb (
        .current_reg(register),
        .direction(direction),
        .ser_in(ser_in),
        .next_reg(next_register)
    );
    
    // 组合逻辑部分 - 输出逻辑
    output_logic #(.WIDTH(W)) out_comb (
        .register(register),
        .direction(direction),
        .ser_out(ser_out)
    );
    
    // 时序逻辑部分 - 寄存器更新
    always @(posedge clock) begin
        if (reset)
            register <= {W{1'b0}};
        else
            register <= next_register;
    end
endmodule

// 组合逻辑模块 - 移位逻辑
module shift_logic #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] current_reg,
    input wire direction,
    input wire ser_in,
    output wire [WIDTH-1:0] next_reg
);
    // 纯组合逻辑实现
    assign next_reg = direction ? 
                     {current_reg[WIDTH-2:0], ser_in} :  // 左移
                     {ser_in, current_reg[WIDTH-1:1]};   // 右移
endmodule

// 组合逻辑模块 - 输出逻辑
module output_logic #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] register,
    input wire direction,
    output wire ser_out
);
    // 纯组合逻辑实现
    assign ser_out = direction ? register[WIDTH-1] : register[0];
endmodule