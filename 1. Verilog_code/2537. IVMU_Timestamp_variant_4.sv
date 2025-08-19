//SystemVerilog
// SystemVerilog
module IVMU_Timestamp #(parameter TS_W=16) (
    input clk,
    input [TS_W-1:0] ts [0:3],
    output reg [1:0] sel
);

// Stage 1: Comparisons
// Input: ts
// Output: comparison results (registered at the end of stage 1)
reg c0_lt_c1_stage1;
reg c0_lt_c2_stage1;
reg c1_lt_c2_stage1;

always @(posedge clk) begin
    c0_lt_c1_stage1 <= ts[0] < ts[1];
    c0_lt_c2_stage1 <= ts[0] < ts[2];
    c1_lt_c2_stage1 <= ts[1] < ts[2];
end

// Stage 2: Evaluate intermediate conditions based on Stage 1 results
// Input: registered comparison results from Stage 1
// Output: intermediate conditions (registered at the end of stage 2)
reg cond1_stage2; // Corresponds to c0_lt_c1 && c0_lt_c2 from stage 1
reg cond2_stage2; // Corresponds to !c0_lt_c1 && c1_lt_c2 from stage 1

always @(posedge clk) begin
    // Use registered comparison results from stage 1
    cond1_stage2 <= c0_lt_c1_stage1 && c0_lt_c2_stage1;
    cond2_stage2 <= !c0_lt_c1_stage1 && c1_lt_c2_stage1;
end

// Stage 3: Determine final sel based on Stage 2 results
// Input: registered intermediate conditions from Stage 2
// Output: sel (registered at the end of stage 3)
// sel is already declared as reg [1:0] sel

always @(posedge clk) begin
    // Use registered intermediate conditions from stage 2
    // Determine sel based on minimum value with tie-breaking
    // sel = 0 if ts[0] is strictly minimum (based on inputs from 3 cycles ago)
    if (cond1_stage2) begin
        sel <= 2'b00;
    end
    // sel = 1 if ts[1] is strictly minimum among {ts[0], ts[1], ts[2]} AND ts[0] is not strictly minimum (based on inputs from 3 cycles ago)
    // This corresponds to ts[0] >= ts[1] && ts[1] < ts[2] based on comparison results from 2 cycles ago
    else if (cond2_stage2) begin
        sel <= 2'b01;
    end
    // sel = 2 otherwise (ts[2] is minimum or tie-breaking favors 2 or 1, based on inputs from 3 cycles ago)
    else begin
        sel <= 2'b10;
    end
end

endmodule