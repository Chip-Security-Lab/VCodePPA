//SystemVerilog
// SystemVerilog

module IVMU_RoundRobin #(parameter CH=4) (
    input [CH-1:0] irq,
    output reg [$clog2(CH)-1:0] current_ch,

    // Added ports for 8-bit two's complement subtraction
    input [7:0] sub_a,
    input [7:0] sub_b,
    output [7:0] sub_result
);

    // Original priority encoding logic (maintained)
    always @(*) begin
        case (irq)
            4'b0000: current_ch = 2'd0;
            4'b0001: current_ch = 2'd0;
            4'b0010: current_ch = 2'd1;
            4'b0011: current_ch = 2'd1;
            4'b0100: current_ch = 2'd2;
            4'b0101: current_ch = 2'd2;
            4'b0110: current_ch = 2'd2;
            4'b0111: current_ch = 2'd2;
            4'b1000: current_ch = 2'd3;
            4'b1001: current_ch = 2'd3;
            4'b1010: current_ch = 2'd3;
            4'b1011: current_ch = 2'd3;
            4'b1100: current_ch = 2'd3;
            4'b1101: current_ch = 2'd3;
            4'b1110: current_ch = 2'd3;
            4'b1111: current_ch = 2'd3;
            default: current_ch = 2'd0;
        endcase
    end

    // Implementation of 8-bit two's complement subtraction: sub_result = sub_a - sub_b
    // Using the algorithm: A - B = A + (~B) + 1
    wire [7:0] sub_b_inverted;
    wire [8:0] sum_with_carry;

    assign sub_b_inverted = ~sub_b;

    // Perform A + (~B) + 1 using a single addition with carry-in=1
    assign sum_with_carry = {1'b0, sub_a} + {1'b0, sub_b_inverted} + 9'd1;

    // The 8-bit result is the lower 8 bits of the sum
    assign sub_result = sum_with_carry[7:0];

endmodule