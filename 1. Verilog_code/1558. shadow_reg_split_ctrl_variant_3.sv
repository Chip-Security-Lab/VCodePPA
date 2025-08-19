//SystemVerilog
module shadow_reg_split_ctrl_pipeline #(parameter DW=8) (
    input clk, load, update,
    input [DW-1:0] datain,
    output reg [DW-1:0] dataout
);
    reg [DW-1:0] shadow_stage1, shadow_stage2;
    reg valid_stage1, valid_stage2;

    // Lookup table for subtraction
    reg [DW-1:0] lut_sub [0:255]; // 256 entries for 8-bit input

    initial begin
        // Initialize the lookup table for subtraction
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_sub[i] = i - j; // Precompute subtraction results
            end
        end
    end

    // Stage 1: Load data into shadow register
    always @(posedge clk) begin
        if (load) begin
            shadow_stage1 <= datain;
            valid_stage1 <= 1'b1; // Indicate valid data in stage 1
        end else begin
            valid_stage1 <= 1'b0; // Invalidate if not loading
        end
    end

    // Stage 2: Update data output from shadow register using lookup table
    always @(posedge clk) begin
        if (valid_stage1) begin
            shadow_stage2 <= lut_sub[shadow_stage1]; // Use lookup table for subtraction
            valid_stage2 <= 1'b1; // Indicate valid data in stage 2
        end else begin
            valid_stage2 <= 1'b0; // Invalidate if no valid data
        end
    end

    // Final output stage
    always @(posedge clk) begin
        if (valid_stage2) begin
            dataout <= shadow_stage2; // Output the valid data
        end
    end
endmodule