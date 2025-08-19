//SystemVerilog
module CondNor(
    input  signed [7:0] a,
    input  signed [7:0] b,
    output reg y
);
    wire signed [15:0] signed_mult_result;
    wire cond_nor_internal;

    // Optimized signed multiplication using shift-and-add algorithm
    function [15:0] signed_mult_opt;
        input signed [7:0] op_a;
        input signed [7:0] op_b;
        integer i;
        reg [15:0] result;
        reg [15:0] multiplicand;
        reg [7:0] multiplier;
        reg sign;
        begin
            // Get sign of result
            sign = op_a[7] ^ op_b[7];
            // Take absolute values
            multiplicand = op_a[7] ? -op_a : op_a;
            multiplier   = op_b[7] ? -op_b : op_b;
            result = 16'd0;
            for(i = 0; i < 8; i = i + 1) begin
                if(multiplier[i])
                    result = result + (multiplicand << i);
            end
            // Restore sign
            if(sign)
                signed_mult_opt = -result;
            else
                signed_mult_opt = result;
        end
    endfunction

    assign signed_mult_result = signed_mult_opt(a, b);

    assign cond_nor_internal = ((a != 0) || (b != 0)) ? 1'b0 : 1'b1;

    always @(*) begin
        y = cond_nor_internal;
    end
endmodule