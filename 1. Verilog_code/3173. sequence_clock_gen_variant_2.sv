//SystemVerilog
module sequence_clock_gen(
    input clk,
    input rst,
    input [7:0] pattern,
    output reg seq_out
);
    // Pipeline stage registers
    reg [2:0] bit_pos_stage1;
    reg [7:0] pattern_stage1;
    reg valid_stage1;
    
    reg seq_out_stage2;
    reg valid_stage2;
    
    // Stage 1: Pattern bit selection and bit position update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_pos_stage1 <= 3'd0;
            pattern_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            bit_pos_stage1 <= bit_pos_stage1 + 3'd1;
            pattern_stage1 <= pattern;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Output generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seq_out_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            seq_out_stage2 <= pattern_stage1[bit_pos_stage1];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final output assignment
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seq_out <= 1'b0;
        end else if (valid_stage2) begin
            seq_out <= seq_out_stage2;
        end
    end
endmodule