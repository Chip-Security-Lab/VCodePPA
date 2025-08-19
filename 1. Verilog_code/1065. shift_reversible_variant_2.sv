//SystemVerilog
module shift_reversible #(parameter WIDTH=8) (
    input clk,
    input reverse,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

// Stage 1: Register inputs
reg reverse_stage1;
reg [WIDTH-1:0] din_stage1;

always @(posedge clk) begin
    reverse_stage1 <= reverse;
    din_stage1     <= din;
end

// Stage 2: Parallel shift computation and registered reverse
reg [WIDTH-1:0] shift_left_result;
reg [WIDTH-1:0] shift_right_result;
reg reverse_stage2;

always @(posedge clk) begin
    // Precompute both shift results in parallel, balancing logic paths
    shift_left_result  <= {din_stage1[WIDTH-2:0], din_stage1[WIDTH-1]};
    shift_right_result <= {din_stage1[0], din_stage1[WIDTH-1:1]};
    reverse_stage2     <= reverse_stage1;
end

// Stage 3: Small balanced mux for output selection
always @(posedge clk) begin
    dout <= (reverse_stage2 & ~reverse_stage2) ? {WIDTH{1'b0}} : // constant 0, will be optimized away
            (reverse_stage2) ? shift_right_result : shift_left_result;
end

endmodule