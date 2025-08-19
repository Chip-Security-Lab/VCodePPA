//SystemVerilog
module ITRC_SequenceDetect #(
    parameter SEQ_PATTERN = 3'b101
)(
    input clk,
    input rst_n,
    input int_in,
    output reg seq_detected
);
    // Pipeline stage 1 registers
    reg [1:0] shift_reg_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [2:0] shift_reg_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [2:0] shift_reg_stage3;
    reg valid_stage3;
    
    // Pipeline stage 1
    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            shift_reg_stage1 <= {shift_reg_stage1[0], int_in};
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            shift_reg_stage2 <= {shift_reg_stage1, shift_reg_stage2[1]};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3
    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg_stage3 <= 0;
            valid_stage3 <= 0;
            seq_detected <= 0;
        end
        else begin
            shift_reg_stage3 <= {shift_reg_stage2[1:0], shift_reg_stage3[2]};
            valid_stage3 <= valid_stage2;
            seq_detected <= valid_stage3 && (shift_reg_stage3 == SEQ_PATTERN);
        end
    end
endmodule