//SystemVerilog
module shift_multiphase #(parameter WIDTH=8) (
    input clk0, clk1,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    wire [WIDTH-1:0] phase_shifted;
    wire [WIDTH-1:0] subtractor_result;
    wire borrow_out;
    reg [WIDTH-1:0] phase_reg;

    // Move phase_reg register after phase_shifted (forward retiming)
    assign phase_shifted = { {2{1'b0}}, din[WIDTH-1:2] }; // din << 2

    always @ (posedge clk0) begin
        phase_reg <= din;
    end

    conditional_invert_subtractor #(.WIDTH(WIDTH)) u_conditional_invert_subtractor (
        .a(phase_reg),
        .b(phase_shifted), // din << 2, not phase_reg << 2 (retimed)
        .invert_b(1'b1),
        .borrow_in(1'b0),
        .diff(subtractor_result),
        .borrow_out(borrow_out)
    );

    always @ (posedge clk1) begin
        dout <= subtractor_result;
    end
endmodule

module conditional_invert_subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input invert_b,
    input borrow_in,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    wire [WIDTH-1:0] b_xor;
    assign b_xor = b ^ {WIDTH{invert_b}};
    assign {borrow_out, diff} = {1'b0, a} + {1'b0, b_xor} + { {WIDTH{1'b0}}, invert_b ^ borrow_in };
endmodule