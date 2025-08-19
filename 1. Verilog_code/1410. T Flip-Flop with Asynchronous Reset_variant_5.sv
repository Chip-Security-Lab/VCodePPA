//SystemVerilog
module t_ff_async_reset (
    input wire clk,
    input wire rst_n,
    input wire t,
    input wire valid_in,  // Input valid signal
    output wire valid_out, // Output valid signal
    output wire q
);
    // Stage 1: Input processing
    reg t_stage1;
    reg q_current_stage1;
    reg valid_stage1;
    
    // Stage 2: Compute next state
    reg q_next_stage2;
    reg valid_stage2;
    
    // Stage 3: Output register
    reg q_output_stage3;
    reg valid_stage3;
    
    // Pipeline Stage 1: T signal capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_stage1 <= 1'b0;
        end
        else begin
            t_stage1 <= t;
        end
    end
    
    // Pipeline Stage 1: Current state feedback
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_current_stage1 <= 1'b0;
        end
        else begin
            q_current_stage1 <= q_output_stage3; // Feedback from output
        end
    end
    
    // Pipeline Stage 1: Valid signal handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline Stage 2: T flip-flop state computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_next_stage2 <= 1'b0;
        end
        else begin
            q_next_stage2 <= t_stage1 ? ~q_current_stage1 : q_current_stage1;
        end
    end
    
    // Pipeline Stage 2: Valid signal propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Output data register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_output_stage3 <= 1'b0;
        end
        else begin
            q_output_stage3 <= q_next_stage2;
        end
    end
    
    // Pipeline Stage 3: Output valid register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end
        else begin
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Assign outputs
    assign q = q_output_stage3;
    assign valid_out = valid_stage3;
    
endmodule