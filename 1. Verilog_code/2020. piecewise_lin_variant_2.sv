//SystemVerilog
module piecewise_lin #(
    parameter N = 3
)(
    input  [15:0] x,
    input  [15:0] knots_array [(N-1):0],
    input  [15:0] slopes_array [(N-1):0],
    output [15:0] y
);
    reg [15:0] seg;
    integer i;

    wire [15:0] diff_array [N-1:0];
    wire [15:0] prod_array [N-1:0];
    wire        gt_array   [N-1:0];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_DIFFS
            assign gt_array[gi] = (x > knots_array[gi]);
            assign diff_array[gi] = x - knots_array[gi];
            assign prod_array[gi] = gt_array[gi] ? carry_lookahead_adder_mult16(slopes_array[gi], diff_array[gi]) : 16'd0;
        end
    endgenerate

    // Carry Lookahead Adder for 16 bits
    function [15:0] carry_lookahead_adder16;
        input [15:0] a;
        input [15:0] b;
        input        cin;
        reg   [15:0] g, p, c;
        integer      j;
        begin
            g = a & b;
            p = a ^ b;
            c[0] = cin;
            for (j = 1; j < 16; j = j + 1)
                c[j] = g[j-1] | (p[j-1] & c[j-1]);
            carry_lookahead_adder16 = p ^ c;
        end
    endfunction

    // Multiplier using normal * operator, but sum with CLA adder
    function [15:0] carry_lookahead_adder_mult16;
        input [15:0] a;
        input [15:0] b;
        reg   [31:0] mult_result;
        begin
            mult_result = a * b;
            // Only lower 16 bits needed for this algorithm
            carry_lookahead_adder_mult16 = mult_result[15:0];
        end
    endfunction

    reg [15:0] sum_temp [N:0];

    always @(*) begin : SEGMENT_SUM
        sum_temp[0] = 16'd0;
        for (i = 0; i < N; i = i + 1) begin
            sum_temp[i+1] = carry_lookahead_adder16(sum_temp[i], prod_array[i], 1'b0);
        end
        seg = sum_temp[N];
    end

    assign y = seg;

endmodule