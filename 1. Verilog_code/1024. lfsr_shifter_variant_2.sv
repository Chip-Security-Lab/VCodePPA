//SystemVerilog
module lfsr_shifter #(parameter W = 8) (
    input  wire              clk,
    input  wire              rst,
    output reg  [W-1:0]      prbs
);

    // 7-bit two's complement subtractor for feedback calculation
    function [6:0] twos_complement_sub;
        input [6:0] a;
        input [6:0] b;
        reg   [6:0] b_inverted;
        reg         carry_in;
        begin
            b_inverted = ~b;
            carry_in   = 1'b1;
            twos_complement_sub = a + b_inverted + carry_in;
        end
    endfunction

    wire feedback_bit;
    wire [6:0] prbs_upper;
    wire [6:0] prbs_lower;
    wire [6:0] sub_result;

    assign prbs_upper = {6'b0, prbs[7]};
    assign prbs_lower = {6'b0, prbs[5]};
    assign sub_result = twos_complement_sub(prbs_upper, prbs_lower);
    assign feedback_bit = sub_result[0];

    always @(posedge clk or posedge rst) begin
        if (rst)
            prbs <= 8'hFF;
        else
            prbs <= {prbs[6:0], feedback_bit};
    end

endmodule