//SystemVerilog
module shift_enable_chain #(parameter WIDTH=8) (
    input clk,
    input en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

reg [WIDTH-1:0] buffer;
wire [WIDTH-1:0] shifted_buffer;
wire [WIDTH-1:0] one_vector;
wire [WIDTH-1:0] negated_one_vector;
wire [WIDTH-1:0] shifted_buffer_minus_one;
wire carry_out;

// 8'b00000001 for subtraction by 1
assign one_vector = { {(WIDTH-1){1'b0}}, 1'b1 };

// Shift buffer left by 1 (LSB is 0)
assign shifted_buffer = {buffer[WIDTH-2:0], 1'b0};

// Two's complement for subtraction (subtraction by 1): shifted_buffer + (~one_vector + 1)
assign negated_one_vector = ~one_vector;
assign {carry_out, shifted_buffer_minus_one} = shifted_buffer + negated_one_vector + 1'b1;

always @(posedge clk) begin
    if (en) begin
        buffer <= din;
        dout <= shifted_buffer_minus_one;
    end else begin
        buffer <= buffer;
        dout <= dout;
    end
end

endmodule