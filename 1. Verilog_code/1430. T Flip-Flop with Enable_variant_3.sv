//SystemVerilog
module t_ff_enable (
    input wire clk,
    input wire en,
    input wire t,
    output reg q
);
    // Pipeline stage 1: Input capture
    reg en_stage1, t_stage1, q_feedback_stage1;
    
    // Pipeline stage 2: Logic computation
    reg toggle_stage2;
    
    // Pipeline stage 3: Output determination
    reg q_next_stage3;
    
    always @(posedge clk) begin
        // Stage 1: Capture inputs
        en_stage1 <= en;
        t_stage1 <= t;
        q_feedback_stage1 <= q;
        
        // Stage 2: Compute toggle condition
        toggle_stage2 <= en_stage1 & t_stage1;
        
        // Stage 3: Determine next q value
        q_next_stage3 <= toggle_stage2 ? ~q_feedback_stage1 : q_feedback_stage1;
        
        // Final stage: Update output
        q <= q_next_stage3;
    end
endmodule