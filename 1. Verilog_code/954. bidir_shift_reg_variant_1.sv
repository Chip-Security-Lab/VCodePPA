//SystemVerilog
module bidir_shift_reg #(parameter W = 16) (
    input clock, reset,
    input direction,     // 0: right, 1: left
    input ser_in,
    output reg ser_out
);
    reg [W-1:0] register;
    reg [W-1:0] next_register;
    wire right_shift = ~direction;
    
    // 使用if-else结构替代条件运算符计算下一个寄存器状态
    always @(*) begin
        if (right_shift) begin
            next_register = {ser_in, register[W-1:1]};
        end else begin
            next_register = {register[W-2:0], ser_in};
        end
    end
    
    always @(posedge clock) begin
        if (reset)
            register <= {W{1'b0}};
        else
            register <= next_register;
    end
    
    // 使用if-else结构替代条件运算符选择输出
    always @(*) begin
        if (right_shift) begin
            ser_out = register[0];
        end else begin
            ser_out = register[W-1];
        end
    end
endmodule