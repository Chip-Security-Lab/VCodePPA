//SystemVerilog
module shift_thermometer #(parameter WIDTH=8) (
    input clk,
    input dir,
    output reg [WIDTH-1:0] therm
);

wire [WIDTH-1:0] right_shifted;
wire [WIDTH-1:0] left_shifted;
wire [WIDTH-1:0] right_shift_in;
wire [WIDTH-1:0] left_shift_in;
wire [WIDTH-1:0] subtractor_b;
wire [WIDTH-1:0] subtractor_inverted_b;
wire [WIDTH-1:0] subtractor_sum;
wire subtractor_carry_in;
wire subtractor_carry_out;

// Conditional Invert Subtractor (therm - 1)
assign subtractor_b = { {(WIDTH-1){1'b0}}, 1'b1 }; // Subtract 1
assign subtractor_inverted_b = ~subtractor_b;
assign subtractor_carry_in = 1'b1; // For subtract: invert B and add 1

assign subtractor_sum = therm + subtractor_inverted_b + subtractor_carry_in;

// Right shift: replace therm <= therm - 1 by using conditional invert subtractor
assign right_shifted = subtractor_sum;

// Left shift: original logic
assign left_shifted = (therm << 1) | 1'b1;

always @(posedge clk) begin
    if (dir) begin
        therm <= right_shifted;
    end else begin
        therm <= left_shifted;
    end
end

endmodule