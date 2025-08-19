//SystemVerilog
module Div4(
    input [7:0] D, d,
    output [7:0] Q, R
);
    wire [8:0] R_temp;
    wire [7:0] Q_temp;

    // Instantiate the division core module
    DivisionCore div_core (
        .D(D),
        .d(d),
        .Q(Q_temp),
        .R(R_temp)
    );

    // Instantiate the result processing module
    ResultProcessor result_proc (
        .Q_in(Q_temp),
        .R_in(R_temp),
        .Q_out(Q),
        .R_out(R)
    );

endmodule

module DivisionCore(
    input [7:0] D, d,
    output reg [7:0] Q,
    output reg [8:0] R
);
    integer i;
    wire [8:0] d_neg;

    // Two's complement calculation module
    TwoComplement twos_comp (
        .d(d),
        .d_neg(d_neg)
    );

    always @(*) begin
        R = {1'b0, D};
        Q = 0;
        for(i = 0; i < 8; i = i + 1) begin
            R = {R[7:0], 1'b0};
            if(R[8:4] >= d) begin
                R = R + d_neg;
                Q[7-i] = 1'b1;
            end
        end
    end
endmodule

module TwoComplement(
    input [7:0] d,
    output [8:0] d_neg
);
    assign d_neg = {1'b1, ~d} + 1'b1;
endmodule

module ResultProcessor(
    input [7:0] Q_in,
    input [8:0] R_in,
    output [7:0] Q_out,
    output [7:0] R_out
);
    assign Q_out = Q_in;
    assign R_out = R_in[7:0] >> 1;
endmodule