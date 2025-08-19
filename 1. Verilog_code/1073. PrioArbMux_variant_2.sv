//SystemVerilog
module PrioArbMux #(parameter DW=4) (
    input  [3:0] req,
    input        en,
    output reg [1:0] grant,
    output     [DW-1:0] data
);

wire [1:0] prio_grant;

// Instantiate 4-bit borrow lookahead subtractor
wire [3:0] sub_a = req;
wire [3:0] sub_b = 4'b0001;
wire       sub_borrow_out;
wire [3:0] sub_diff;

BorrowLookaheadSubtractor4 sub_inst (
    .minuend(sub_a),
    .subtrahend(sub_b),
    .borrow_in(1'b0),
    .difference(sub_diff),
    .borrow_out(sub_borrow_out)
);

// Use subtractor result to determine priority grant
assign prio_grant = sub_diff[3] ? 2'b11 :
                    sub_diff[2] ? 2'b10 :
                    sub_diff[1] ? 2'b01 : 2'b00;

always @* begin
    grant = en ? prio_grant : 2'b00;
end

assign data = {grant, {DW-2{1'b0}}};

endmodule

// 4-bit Borrow Lookahead Subtractor
module BorrowLookaheadSubtractor4 (
    input  [3:0] minuend,
    input  [3:0] subtrahend,
    input        borrow_in,
    output [3:0] difference,
    output       borrow_out
);

wire [3:0] generate_borrow;
wire [3:0] propagate_borrow;
wire [3:0] borrow;

// Generate and propagate
assign generate_borrow[0] = (~minuend[0]) & subtrahend[0];
assign propagate_borrow[0] = ~(minuend[0] ^ subtrahend[0]);

assign generate_borrow[1] = (~minuend[1]) & subtrahend[1];
assign propagate_borrow[1] = ~(minuend[1] ^ subtrahend[1]);

assign generate_borrow[2] = (~minuend[2]) & subtrahend[2];
assign propagate_borrow[2] = ~(minuend[2] ^ subtrahend[2]);

assign generate_borrow[3] = (~minuend[3]) & subtrahend[3];
assign propagate_borrow[3] = ~(minuend[3] ^ subtrahend[3]);

// Borrow chain
assign borrow[0] = generate_borrow[0] | (propagate_borrow[0] & borrow_in);
assign borrow[1] = generate_borrow[1] | (propagate_borrow[1] & borrow[0]);
assign borrow[2] = generate_borrow[2] | (propagate_borrow[2] & borrow[1]);
assign borrow[3] = generate_borrow[3] | (propagate_borrow[3] & borrow[2]);

// Difference
assign difference[0] = minuend[0] ^ subtrahend[0] ^ borrow_in;
assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
assign difference[3] = minuend[3] ^ subtrahend[3] ^ borrow[2];

assign borrow_out = borrow[3];

endmodule