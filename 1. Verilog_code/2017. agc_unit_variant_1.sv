//SystemVerilog
module agc_unit #(parameter W=16)(
    input clk,
    input [W-1:0] in,
    output reg [W-1:0] out
);
    // Input register buffer for fanout reduction
    reg [W-1:0] in_reg_stage1;
    reg [W-1:0] in_reg_stage2;

    // Peak register buffer for fanout reduction
    reg [W+1:0] peak_reg;
    reg [W+1:0] peak_next_stage1;
    reg [W+1:0] peak_next_stage2;

    reg [W-1:0] out_next;

    // First stage: buffer input register
    always @(posedge clk) begin
        in_reg_stage1 <= in;
    end

    // Second stage: buffer input register again for fanout reduction
    always @(posedge clk) begin
        in_reg_stage2 <= in_reg_stage1;
    end

    // First stage: buffer peak_next
    always @* begin
        peak_next_stage1 = (in_reg_stage2 > peak_reg) ? in_reg_stage2 : peak_reg - (peak_reg >> 3);
    end

    // Second stage: buffer peak_next again for fanout reduction
    always @(posedge clk) begin
        peak_next_stage2 <= peak_next_stage1;
    end

    // Calculate output next value
    always @* begin
        out_next = (in_reg_stage2 * 32767) / (peak_next_stage2 ? peak_next_stage2 : 1);
    end

    // Main registers update
    always @(posedge clk) begin
        peak_reg <= peak_next_stage2;
        out <= out_next;
    end

endmodule