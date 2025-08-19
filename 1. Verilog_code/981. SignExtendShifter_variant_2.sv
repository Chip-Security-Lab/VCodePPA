//SystemVerilog
module SignExtendShifter #(
    parameter WIDTH = 8
) (
    input  wire                   clk,
    input  wire                   arith_shift,
    input  wire signed [WIDTH-1:0] data_in,
    output reg  signed [WIDTH-1:0] data_out
);

// Stage 1: Input Register
reg signed [WIDTH-1:0] data_stage1;
reg                    arith_shift_stage1;

always @(posedge clk) begin
    data_stage1         <= data_in;
    arith_shift_stage1  <= arith_shift;
end

// Stage 2: Shift Operation
reg signed [WIDTH-1:0] shifted_data_stage2;

always @(posedge clk) begin
    if (arith_shift_stage1)
        shifted_data_stage2 <= data_stage1 >>> 1;    // Arithmetic right shift
    else
        shifted_data_stage2 <= data_stage1 << 1;     // Logical left shift
end

// Stage 3: Output Register
always @(posedge clk) begin
    data_out <= shifted_data_stage2;
end

endmodule