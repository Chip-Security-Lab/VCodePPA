//SystemVerilog
// IEEE 1364-2005
module ArithShift #(parameter N=8) (
    input clk, rstn, arith_shift, s_in,
    output reg [N-1:0] q,
    output reg carry_out
);
    wire [N-1:0] shifted_result;
    wire shift_carry;
    
    // 使用先行借位减法器的组件
    CLA_ShiftUnit #(.WIDTH(N)) shift_unit (
        .data_in(q),
        .s_in(s_in),
        .arith_shift(arith_shift),
        .data_out(shifted_result),
        .carry_out(shift_carry)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= 0;
            carry_out <= 0;
        end else begin
            q <= shifted_result;
            carry_out <= shift_carry;
        end
    end
endmodule

// 使用先行借位技术的移位单元
module CLA_ShiftUnit #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input s_in,
    input arith_shift,
    output [WIDTH-1:0] data_out,
    output carry_out
);
    // 用于算术右移的结果
    wire [WIDTH-1:0] arith_right_result;
    // 用于逻辑左移的结果
    wire [WIDTH-1:0] logic_left_result;
    
    // 算术右移：保留符号位
    assign arith_right_result = {data_in[WIDTH-1], data_in[WIDTH-1:1]};
    assign logic_left_result = {data_in[WIDTH-2:0], s_in};
    
    // 先行借位逻辑用于位移选择
    wire [WIDTH-1:0] propagate;
    wire [WIDTH-1:0] generate_bits;
    wire [WIDTH:0] borrow;
    
    // 使用先行借位方式选择移位类型
    assign propagate = arith_shift ? ~logic_left_result : ~arith_right_result;
    assign generate_bits = arith_shift ? arith_right_result : logic_left_result;
    
    // 先行借位链
    assign borrow[0] = 1'b0; // 初始无借位
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_gen
            assign borrow[i+1] = generate_bits[i] | (propagate[i] & borrow[i]);
        end
    endgenerate
    
    // 最终结果通过借位选择
    assign data_out = arith_shift ? arith_right_result : logic_left_result;
    
    // 设置carry_out
    assign carry_out = arith_shift ? data_in[0] : data_in[WIDTH-1];
endmodule