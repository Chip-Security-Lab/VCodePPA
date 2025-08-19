//SystemVerilog
module shift_thermometer #(parameter WIDTH=8) (
    input clk,
    input dir,
    output [WIDTH-1:0] therm
);

reg [WIDTH-1:0] therm_reg;
wire [WIDTH-1:0] next_therm;

// 8-bit parallel borrow lookahead subtractor
function [WIDTH-1:0] borrow_lookahead_sub;
    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;
    reg [WIDTH:0] borrow;
    integer i;
begin
    borrow[0] = 1'b0;
    for (i = 0; i < WIDTH; i = i + 1) begin
        borrow[i+1] = (~a[i] & b[i]) | (b[i] & borrow[i]) | (~a[i] & borrow[i]);
    end
    for (i = 0; i < WIDTH; i = i + 1) begin
        borrow_lookahead_sub[i] = a[i] ^ b[i] ^ borrow[i];
    end
end
endfunction

wire [WIDTH-1:0] right_shifted, left_shifted;
wire [WIDTH-1:0] right_subtrahend, left_addend;

// For right shift: subtract 1 from current pattern using borrow lookahead subtractor
assign right_subtrahend = {{(WIDTH-1){1'b0}}, 1'b1};
assign right_shifted = borrow_lookahead_sub(therm_reg, right_subtrahend);

// For left shift: add 1 to current pattern (no need for borrow lookahead, simple adder)
assign left_addend = {{(WIDTH-1){1'b0}}, 1'b1};
assign left_shifted = therm_reg + left_addend;

// Select next state based on direction
assign next_therm = dir ? right_shifted : left_shifted;

always @(posedge clk) begin
    therm_reg <= next_therm;
end

assign therm = therm_reg;

endmodule