//SystemVerilog
module clock_multiplier #(
    parameter MULT_RATIO = 4,
    parameter COUNTER_WIDTH = 2
)(
    input clk_ref,
    output clk_out
);

wire [COUNTER_WIDTH-1:0] phase_count;

phase_counter #(
    .COUNTER_WIDTH(COUNTER_WIDTH)
) u_phase_counter (
    .clk_ref(clk_ref),
    .phase_count(phase_count)
);

phase_to_clock #(
    .COUNTER_WIDTH(COUNTER_WIDTH)
) u_phase_to_clock (
    .phase_count(phase_count),
    .clk_out(clk_out)
);

endmodule

module phase_counter #(
    parameter COUNTER_WIDTH = 2
)(
    input clk_ref,
    output reg [COUNTER_WIDTH-1:0] phase_count
);

wire [COUNTER_WIDTH-1:0] next_phase_count;
wire [COUNTER_WIDTH:0] borrow;
wire [COUNTER_WIDTH-1:0] ones_complement;

// Generate ones complement for subtraction
assign ones_complement = ~(phase_count);

// Implement lookahead borrow subtractor (equivalent to incrementer)
// Initialize borrow-in to 1 for two's complement addition
assign borrow[0] = 1'b1;

// Generate borrows with lookahead logic
genvar i;
generate
    for (i = 0; i < COUNTER_WIDTH; i = i + 1) begin : gen_borrow
        assign next_phase_count[i] = ones_complement[i] ^ borrow[i];
        assign borrow[i+1] = ones_complement[i] & borrow[i];
    end
endgenerate

always @(negedge clk_ref) begin
    phase_count <= next_phase_count;
end

endmodule

module phase_to_clock #(
    parameter COUNTER_WIDTH = 2
)(
    input [COUNTER_WIDTH-1:0] phase_count,
    output reg clk_out
);

always @(*) begin
    clk_out = phase_count[1];
end

endmodule