//SystemVerilog
module tff_pulse (
    input clk, rstn, t,
    input valid_in,
    output reg q,
    output reg valid_out
);

    // Stage 1: Input capture and decision making
    reg t_stage1;
    reg valid_stage1;
    reg q_feedback;

    // Stage 2: Toggle calculation
    reg toggle_stage2;
    reg valid_stage2;

    // Stage 1 pipeline: Input capture
    always @(posedge clk) begin
        if (!rstn) begin
            t_stage1 <= 0;
            valid_stage1 <= 0;
            q_feedback <= 0;
        end else begin
            t_stage1 <= t;
            valid_stage1 <= valid_in;
            q_feedback <= q;
        end
    end

    // Stage 2 pipeline: Toggle calculation
    always @(posedge clk) begin
        if (!rstn) begin
            toggle_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (t_stage1 && valid_stage1) begin
            toggle_stage2 <= ~q_feedback;
            valid_stage2 <= valid_stage1;
        end else begin
            toggle_stage2 <= q_feedback;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage pipeline: Update outputs
    always @(posedge clk) begin
        if (!rstn) begin
            q <= 0;
            valid_out <= 0;
        end else begin
            q <= toggle_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule