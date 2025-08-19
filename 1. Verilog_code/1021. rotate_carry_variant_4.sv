//SystemVerilog
module rotate_carry #(parameter W=8) (
    input  wire             clk,
    input  wire             dir,
    input  wire [W-1:0]     din,
    output reg  [W-1:0]     dout,
    output wire             carry
);

reg carry_reg;

wire [W-1:0] rotate_left_result;
wire [W-1:0] rotate_right_result;
wire         left_carry;
wire         right_carry;

// Binary two's complement subtraction for extracting left and right carry bits
wire [W-1:0] right_carry_sub;
wire [W-1:0] left_carry_sub;

assign left_carry_sub  = din - {1'b1, {(W-1){1'b0}}}; // din - 100...0
assign right_carry_sub = din - {{(W-1){1'b0}}, 1'b1}; // din - 00...01

assign left_carry      = left_carry_sub[W-1];
assign right_carry     = right_carry_sub[0];

// Rotate left: {din[W-2:0], din[W-1]}
assign rotate_left_result  = {din[W-2:0], din[W-1]};
// Rotate right: {din[0], din[W-1:1]}
assign rotate_right_result = {din[0], din[W-1:1]};

always @(posedge clk) begin
    if (dir) begin
        dout      <= rotate_left_result;
        carry_reg <= left_carry;
    end else begin
        dout      <= rotate_right_result;
        carry_reg <= right_carry;
    end
end

assign carry = carry_reg;

endmodule