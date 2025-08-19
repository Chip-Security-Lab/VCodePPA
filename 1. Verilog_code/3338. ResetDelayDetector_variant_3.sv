//SystemVerilog
module ResetDelayDetector #(
    parameter DELAY = 4
) (
    input  wire clk,
    input  wire rst_n,
    output wire reset_detected
);

    // Forward register retiming: Move registers after combinational logic

    // Stage 1: Combinational logic for valid and rst_n capture
    wire valid_stage1_comb;
    wire rst_n_stage1_comb;

    assign valid_stage1_comb = rst_n ? 1'b1 : 1'b0;
    assign rst_n_stage1_comb = rst_n;

    // Stage 2: Register valid and rst_n after combinational logic, with delay shift register
    reg [DELAY-1:0] shift_reg_stage2;
    reg valid_stage2;
    reg rst_n_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= {DELAY{1'b1}};
            valid_stage2 <= 1'b0;
            rst_n_stage2 <= 1'b0;
        end else if (valid_stage1_comb) begin
            shift_reg_stage2 <= {shift_reg_stage2[DELAY-2:0], 1'b0};
            valid_stage2 <= 1'b1;
            rst_n_stage2 <= rst_n_stage1_comb;
        end else begin
            valid_stage2 <= 1'b0;
            rst_n_stage2 <= rst_n_stage1_comb;
        end
    end

    // Stage 3: Output register and valid signal
    reg reset_detected_stage3;
    reg valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            reset_detected_stage3 <= shift_reg_stage2[DELAY-1];
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    assign reset_detected = reset_detected_stage3 & valid_stage3;

endmodule