//SystemVerilog
module ITRC_SequenceDetect #(
    parameter SEQ_PATTERN = 3'b101
)(
    input clk,
    input rst_n,
    input int_in,
    output reg seq_detected
);
    // Stage 1 registers
    reg [1:0] shift_reg_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [2:0] shift_reg_stage2;
    reg valid_stage2;
    
    // Stage 1 shift register
    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 2'b0;
        end else begin
            shift_reg_stage1 <= {shift_reg_stage1[0], int_in};
        end
    end
    
    // Stage 1 valid signal
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2 shift register
    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 3'b0;
        end else begin
            shift_reg_stage2 <= {shift_reg_stage1, int_in};
        end
    end
    
    // Stage 2 valid signal
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pattern detection logic
    wire pattern_match;
    assign pattern_match = (shift_reg_stage2 == SEQ_PATTERN);
    
    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            seq_detected <= 1'b0;
        end else begin
            seq_detected <= valid_stage2 && pattern_match;
        end
    end
endmodule