//SystemVerilog
module lut_shifter #(parameter W=4) (
    input  wire              clk,
    input  wire [W-1:0]      din,
    input  wire [1:0]        shift,
    output reg  [W-1:0]      dout
);

// Stage 1: Input register for pipeline (optional, improves timing)
reg [W-1:0] din_stage1;
reg [1:0]   shift_stage1;

always @(posedge clk) begin
    din_stage1   <= din;
    shift_stage1 <= shift;
end

// Stage 2: Precompute all shift results
reg [W-1:0] shift_result_stage2 [0:3];

always @(*) begin
    // Shift amount 0: no shift
    shift_result_stage2[0] = din_stage1;
    // Shift amount 1: shift left by 1
    shift_result_stage2[1] = {din_stage1[W-2:0], 1'b0};
    // Shift amount 2: shift left by 2
    shift_result_stage2[2] = {din_stage1[W-3:0], 2'b00};
    // Shift amount 3: shift left by 3
    shift_result_stage2[3] = {din_stage1[W-4:0], 3'b000};
end

// Stage 3: Pipeline register for shift results
reg [W-1:0] selected_shift_stage3;

always @(posedge clk) begin
    selected_shift_stage3 <= shift_result_stage2[shift_stage1];
end

// Stage 4: Output register for final result
always @(posedge clk) begin
    dout <= selected_shift_stage3;
end

endmodule