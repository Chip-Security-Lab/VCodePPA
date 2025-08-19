//SystemVerilog
// Top-level pipelined 4-input OR reduction module (timing-optimized by forward register retiming)
module DistributedOR (
    input              clk,
    input              rst_n,
    input      [3:0]   bits,
    output reg         result
);

    // Pipeline stage 1: First reduction (pairwise OR) - moved register after combination
    wire or_stage1_0_w = bits[0] | bits[1];
    wire or_stage1_1_w = bits[2] | bits[3];

    reg or_stage1_0;
    reg or_stage1_1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_stage1_0 <= 1'b0;
            or_stage1_1 <= 1'b0;
        end else begin
            or_stage1_0 <= or_stage1_0_w;
            or_stage1_1 <= or_stage1_1_w;
        end
    end

    // Pipeline stage 2: Final OR reduction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            result <= or_stage1_0 | or_stage1_1;
    end

endmodule