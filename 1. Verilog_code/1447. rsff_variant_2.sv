//SystemVerilog
module rsff (
    input wire clk,      // Clock signal
    input wire set,      // Set signal
    input wire reset,    // Reset signal
    output reg q         // Output
);

    // Pipeline registers for input signals
    reg set_stage1, reset_stage1;
    reg set_stage2, reset_stage2;
    
    // Pipeline registers for intermediate results
    reg q_stage1, q_stage2;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        set_stage1 <= set;
        reset_stage1 <= reset;
    end
    
    // Pipeline stage 2: Compute intermediate result
    always @(posedge clk) begin
        if (set_stage1 && !reset_stage1)
            q_stage1 <= 1'b1;
        else if (!set_stage1 && reset_stage1)
            q_stage1 <= 1'b0;
        else if (set_stage1 && reset_stage1)
            q_stage1 <= 1'bx;
        else
            q_stage1 <= q_stage1;
    end
    
    // Pipeline stage 3: Register intermediate result
    always @(posedge clk) begin
        set_stage2 <= set_stage1;
        reset_stage2 <= reset_stage1;
        q_stage2 <= q_stage1;
    end
    
    // Final stage: Output result
    always @(posedge clk) begin
        q <= q_stage2;
    end

endmodule