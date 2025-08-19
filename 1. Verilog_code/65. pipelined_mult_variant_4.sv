//SystemVerilog
module pipelined_mult (
    input clk,
    input rst_n,
    input valid_in,
    input [15:0] a, b,
    output reg valid_out,
    output reg [31:0] result
);
    // Stage 1 registers
    reg [15:0] a_stage1, b_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [15:0] a_stage2, b_stage2;
    reg [31:0] partial_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [31:0] result_stage3;
    reg valid_stage3;

    // Shift-accumulate multiplier signals
    reg [31:0] acc_stage2;
    reg [4:0] shift_cnt_stage2;
    reg [15:0] multiplicand_stage2;
    reg [15:0] multiplier_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            a_stage1 <= 16'd0;
            b_stage1 <= 16'd0;
            valid_stage1 <= 1'b0;
            
            a_stage2 <= 16'd0;
            b_stage2 <= 16'd0;
            partial_stage2 <= 32'd0;
            valid_stage2 <= 1'b0;
            acc_stage2 <= 32'd0;
            shift_cnt_stage2 <= 5'd0;
            multiplicand_stage2 <= 16'd0;
            multiplier_stage2 <= 16'd0;
            
            result_stage3 <= 32'd0;
            valid_stage3 <= 1'b0;
            
            result <= 32'd0;
            valid_out <= 1'b0;
        end else begin
            // Stage 1: Input register
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
            
            // Stage 2: Shift-accumulate multiplication
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            valid_stage2 <= valid_stage1;

            if (valid_stage1) begin
                if (shift_cnt_stage2 == 5'd0) begin
                    multiplicand_stage2 <= a_stage1;
                    multiplier_stage2 <= b_stage1;
                    acc_stage2 <= 32'd0;
                    shift_cnt_stage2 <= 5'd1;
                end else if (shift_cnt_stage2 <= 5'd16) begin
                    if (multiplier_stage2[0]) begin
                        acc_stage2 <= acc_stage2 + multiplicand_stage2;
                    end
                    multiplicand_stage2 <= multiplicand_stage2 << 1;
                    multiplier_stage2 <= multiplier_stage2 >> 1;
                    shift_cnt_stage2 <= shift_cnt_stage2 + 5'd1;
                end
                partial_stage2 <= acc_stage2;
            end else begin
                shift_cnt_stage2 <= 5'd0;
            end
            
            // Stage 3: Output register
            result_stage3 <= partial_stage2;
            valid_stage3 <= valid_stage2;
            
            // Final output
            result <= result_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule