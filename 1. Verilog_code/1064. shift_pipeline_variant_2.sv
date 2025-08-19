//SystemVerilog
module shift_pipeline #(
    parameter WIDTH = 8,
    parameter STAGES = 3
)(
    input wire                  clk,
    input wire  [WIDTH-1:0]     din,
    output wire [WIDTH-1:0]     dout
);

// ==========================
// Optimized Pipeline Structure
// ==========================

// Combine low-complexity shift stages to reduce pipeline depth

reg [WIDTH-1:0] shift_stage1_data;
reg [WIDTH-1:0] shift_stage2_data;

// For STAGES == 1: single shift
// For STAGES == 2: combine two shifts in one stage, output in next stage
// For STAGES >= 3: combine two shifts in one stage, third shift in next stage

generate
if (STAGES == 1) begin : gen_one_stage
    always @(posedge clk) begin
        shift_stage1_data <= din << 1;
    end
    assign dout = shift_stage1_data;
end else if (STAGES == 2) begin : gen_two_stage
    always @(posedge clk) begin
        shift_stage1_data <= din << 2;
        shift_stage2_data <= shift_stage1_data;
    end
    assign dout = shift_stage2_data;
end else begin : gen_three_or_more_stage
    always @(posedge clk) begin
        shift_stage1_data <= din << 2;
        shift_stage2_data <= shift_stage1_data << 1;
    end
    assign dout = shift_stage2_data;
end
endgenerate

endmodule