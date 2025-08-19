//SystemVerilog
module sequence_clock_gen(
    input clk,
    input rst,
    input [7:0] pattern,
    output reg seq_out
);
    // Stage 1 registers
    reg [2:0] bit_pos_stage1;
    reg valid_stage1;
    reg [7:0] pattern_stage1;
    
    // Stage 2 registers
    reg [2:0] bit_pos_stage2;
    reg valid_stage2;
    reg [7:0] pattern_stage2;
    
    // Pipeline Stage 1: Calculate next bit position
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_pos_stage1 <= 3'd0;
            valid_stage1 <= 1'b0;
            pattern_stage1 <= 8'd0;
        end else begin
            bit_pos_stage1 <= bit_pos_stage2 + 3'd1;
            valid_stage1 <= 1'b1;
            pattern_stage1 <= pattern;
        end
    end
    
    // Pipeline Stage 2: Extract the bit from pattern
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_pos_stage2 <= 3'd0;
            valid_stage2 <= 1'b0;
            pattern_stage2 <= 8'd0;
            seq_out <= 1'b0;
        end else begin
            bit_pos_stage2 <= bit_pos_stage1;
            valid_stage2 <= valid_stage1;
            pattern_stage2 <= pattern_stage1;
            
            if (valid_stage2) begin
                seq_out <= pattern_stage2[bit_pos_stage2];
            end else begin
                seq_out <= 1'b0;
            end
        end
    end
endmodule