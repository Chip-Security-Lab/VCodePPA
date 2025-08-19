//SystemVerilog
module async_reset_ring_counter(
    input  wire       clk,
    input  wire       rst_n,  // Active-low reset
    input  wire       enable, // Pipeline enable signal
    output reg  [3:0] q
);
    // Pipeline registers with reduced logic depth
    reg [3:0] stage1_q;
    reg [3:0] stage2_q;
    reg [3:0] stage3_q;
    
    // Pipeline valid signals
    reg stage1_valid;
    reg stage2_valid;
    reg stage3_valid;
    
    // Pre-compute the shift value to reduce critical path
    wire [3:0] next_q = {q[2:0], q[3]};
    
    // Stage 1: Initial shift operation with balanced logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_q <= 4'b0001; // Reset to initial state
            stage1_valid <= 1'b0;
        end else if (enable) begin
            stage1_q <= next_q;   // Use pre-computed value
            stage1_valid <= 1'b1;
        end
    end
    
    // Stage 2: Second processing stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_q <= 4'b0001;
            stage2_valid <= 1'b0;
        end else if (enable) begin
            stage2_q <= stage1_q;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Stage 3: Final processing stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_q <= 4'b0001;
            stage3_valid <= 1'b0;
        end else if (enable) begin
            stage3_q <= stage2_q;
            stage3_valid <= stage2_valid;
        end
    end
    
    // Output assignment with simplified condition logic
    // Split complex condition evaluation for better timing
    wire output_valid = enable && stage3_valid;
    wire startup_mode = enable && !stage3_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b0001; // Reset to initial state
        end else if (output_valid) begin
            q <= stage3_q;
        end else if (startup_mode) begin
            // During pipeline startup
            q <= next_q;
        end
    end
endmodule