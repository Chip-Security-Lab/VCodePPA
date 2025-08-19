//SystemVerilog

module generic_rounder #(
    parameter WIDTH = 16,
    parameter ROUND_BITS = 3
)(
    input  [WIDTH+ROUND_BITS-1:0] data_in,
    input                         round_en,
    output [WIDTH-1:0]            data_out
);

reg [WIDTH-1:0] rounded_value;
assign data_out = rounded_value;

always @(*) begin
    if (round_en) begin
        if (|data_in[ROUND_BITS-1:0]) begin
            rounded_value = data_in[WIDTH+ROUND_BITS-1:ROUND_BITS] + 1'b1;
        end else begin
            rounded_value = data_in[WIDTH+ROUND_BITS-1:ROUND_BITS];
        end
    end else begin
        rounded_value = data_in[WIDTH+ROUND_BITS-1:ROUND_BITS];
    end
end

endmodule

module dynamic_rounder #(
    parameter W = 16
)(
    input  [W+2:0] in,
    input          mode,
    output [W-1:0] out
);

generic_rounder #(
    .WIDTH(W),
    .ROUND_BITS(3)
) u_generic_rounder (
    .data_in(in),
    .round_en(mode),
    .data_out(out)
);

endmodule