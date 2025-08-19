//SystemVerilog
module decoder_hier #(parameter NUM_SLAVES=4) (
    input [7:0] addr,
    output reg [3:0] high_decode,
    output reg [3:0] low_decode
);

wire [3:0] high_decode_next;
wire [3:0] low_decode_next;

// High decode multiplexer using Karatsuba multiplication
wire [3:0] high_half = addr[7:4];
wire [3:0] high_mask = (high_half < NUM_SLAVES) ? 4'b0001 : 4'b0000;
wire [3:0] high_shift = high_half[1:0];
wire [3:0] high_shift2 = high_half[3:2];

// Karatsuba multiplication for high decode
wire [3:0] high_part1 = high_mask << high_shift;
wire [3:0] high_part2 = high_mask << (high_shift2 << 1);
assign high_decode_next = high_part1 | high_part2;

// Low decode multiplexer using Karatsuba multiplication
wire [3:0] low_half = addr[3:0];
wire [3:0] low_shift = low_half[1:0];
wire [3:0] low_shift2 = low_half[3:2];

// Karatsuba multiplication for low decode
wire [3:0] low_part1 = 4'b0001 << low_shift;
wire [3:0] low_part2 = 4'b0001 << (low_shift2 << 1);
assign low_decode_next = low_part1 | low_part2;

// Register outputs
always @* begin
    high_decode = high_decode_next;
    low_decode = low_decode_next;
end

endmodule