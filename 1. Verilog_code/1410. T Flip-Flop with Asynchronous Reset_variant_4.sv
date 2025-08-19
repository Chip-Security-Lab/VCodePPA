//SystemVerilog
module t_ff_async_reset_pipelined (
    input wire clk,
    input wire rst_n,
    input wire t,
    input wire valid_in,
    output wire valid_out,
    output wire q
);
    // Stage 1: Input registration and operation determination
    reg t_stage1;
    reg q_feedback_stage1;
    reg valid_stage1;
    wire toggle_stage1;
    
    // Stage 2: State update
    reg toggle_stage2;
    reg valid_stage2;
    reg q_reg;
    
    // Compute toggle operation in stage 1
    assign toggle_stage1 = t_stage1 ? ~q_feedback_stage1 : q_feedback_stage1;
    
    // Output assignment
    assign q = q_reg;
    assign valid_out = valid_stage2;
    
    // Stage 1 pipeline registers - flattened control structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_stage1 <= 1'b0;
            q_feedback_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (valid_in) begin
            t_stage1 <= t;
            q_feedback_stage1 <= q_reg;
            valid_stage1 <= 1'b1;
        end else begin
            t_stage1 <= 1'b0;
            q_feedback_stage1 <= q_reg;
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2 pipeline registers - flattened control structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            q_reg <= 1'b0;
        end else if (valid_stage1) begin
            toggle_stage2 <= toggle_stage1;
            valid_stage2 <= 1'b1;
            q_reg <= toggle_stage2;
        end else begin
            toggle_stage2 <= toggle_stage2;
            valid_stage2 <= 1'b0;
            q_reg <= q_reg;
        end
    end
endmodule