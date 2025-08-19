//SystemVerilog
module interleave_shift (
    input clk,
    input [7:0] din,
    output reg [7:0] dout
);

reg [7:0] din_reg;
reg [7:0] interleave_data;
reg [7:0] minuend;
reg [7:0] subtrahend;
wire [7:0] difference;
wire borrow_out;

always @(posedge clk) begin
    din_reg <= din;
    interleave_data <= {din_reg[6], din_reg[4], din_reg[2], din_reg[0],
                        din_reg[7], din_reg[5], din_reg[3], din_reg[1]};
    minuend <= din_reg;
    subtrahend <= interleave_data;
    dout <= difference;
end

carry_lookahead_borrow_subtractor_8bit u_subtractor (
    .a(minuend),
    .b(subtrahend),
    .diff(difference),
    .borrow_out(borrow_out)
);

endmodule

module carry_lookahead_borrow_subtractor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff,
    output       borrow_out
);

wire [7:0] generate_borrow;
wire [7:0] propagate_borrow;
wire [8:0] borrow_chain;

// Generate and Propagate for Borrow
assign generate_borrow   = (~a) & b;
assign propagate_borrow  = ~(a ^ b);

// Initial borrow_in is 0
assign borrow_chain[0] = 1'b0;

// Generate borrow chain using carry-lookahead for borrow
assign borrow_chain[1] = generate_borrow[0] | (propagate_borrow[0] & borrow_chain[0]);
assign borrow_chain[2] = generate_borrow[1] | (propagate_borrow[1] & borrow_chain[1]);
assign borrow_chain[3] = generate_borrow[2] | (propagate_borrow[2] & borrow_chain[2]);
assign borrow_chain[4] = generate_borrow[3] | (propagate_borrow[3] & borrow_chain[3]);
assign borrow_chain[5] = generate_borrow[4] | (propagate_borrow[4] & borrow_chain[4]);
assign borrow_chain[6] = generate_borrow[5] | (propagate_borrow[5] & borrow_chain[5]);
assign borrow_chain[7] = generate_borrow[6] | (propagate_borrow[6] & borrow_chain[6]);
assign borrow_chain[8] = generate_borrow[7] | (propagate_borrow[7] & borrow_chain[7]);

// Subtract
assign diff = a ^ b ^ borrow_chain[7:0];
assign borrow_out = borrow_chain[8];

endmodule