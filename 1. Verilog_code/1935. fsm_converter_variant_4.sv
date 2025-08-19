//SystemVerilog
module fsm_converter #(parameter S_WIDTH=4) (
    input  [S_WIDTH-1:0] state_in,
    output reg [2**S_WIDTH-1:0] state_out
);

    wire [S_WIDTH-1:0] adder_result;
    reg [2**S_WIDTH-1:0] onehot_state;

    // 4-bit carry lookahead adder instantiation
    carry_lookahead_adder_4bit cla_adder (
        .a(state_in),
        .b({S_WIDTH{1'b0}}),   // No offset, add zero
        .cin(1'b0),
        .sum(adder_result),
        .cout()
    );

    // Generate one-hot state
    always @(*) begin : onehot_gen
        onehot_state = {2**S_WIDTH{1'b0}};
        onehot_state[adder_result] = 1'b1;
    end

    // Output assignment
    always @(*) begin : state_out_assign
        state_out = onehot_state;
    end

endmodule

module carry_lookahead_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] p; // propagate
    wire [3:0] g; // generate
    wire [4:0] carry;

    assign p = a ^ b;
    assign g = a & b;

    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry[0]);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry[0]);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & carry[0]);

    assign sum = p ^ carry[3:0];
    assign cout = carry[4];
endmodule