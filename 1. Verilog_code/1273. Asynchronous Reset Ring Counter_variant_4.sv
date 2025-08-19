//SystemVerilog
module async_reset_ring_counter (
    input  wire       clk,
    input  wire       rst_n,  // Active-low reset
    output reg  [3:0] q,
    input  wire       enable, // New input to control pipeline flow
    output reg        valid_out // Output valid signal
);
    // Pipeline stage registers with more balanced computation
    reg [3:0] stage1_q;
    reg [3:0] stage2_q;
    reg [3:0] stage3_q;
    
    // Pipeline valid signals for better control
    reg stage1_valid;
    reg stage2_valid;
    reg stage3_valid;
    
    // Pipeline ready signals for backpressure support
    wire stage3_ready = 1'b1; // Output always ready in this implementation
    wire stage2_ready = !stage2_valid || stage3_ready;
    wire stage1_ready = !stage1_valid || stage2_ready;
    
    // Pre-compute circular shift variations for better timing
    wire [3:0] rotate1 = {q[2:0], q[3]};       // Rotate right by 1
    wire [3:0] rotate2 = {q[1:0], q[3:2]};     // Rotate right by 2
    
    // Stage 1: Generate and select appropriate rotation
    // This distributes computation more evenly across stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_q <= 4'b0001;
            stage1_valid <= 1'b0;
        end
        else if (stage1_ready && enable) begin
            stage1_q <= rotate1;
            stage1_valid <= 1'b1;
        end
        else if (stage1_ready && !enable) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // Stage 2: Further processing (in real designs, this would do actual work)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_q <= 4'b0001;
            stage2_valid <= 1'b0;
        end
        else if (stage2_ready) begin
            if (stage1_valid) begin
                stage2_q <= stage1_q;
                stage2_valid <= 1'b1;
            end
            else begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // Stage 3: Final processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_q <= 4'b0001;
            stage3_valid <= 1'b0;
        end
        else if (stage3_ready) begin
            if (stage2_valid) begin
                stage3_q <= stage2_q;
                stage3_valid <= 1'b1;
            end
            else begin
                stage3_valid <= 1'b0;
            end
        end
    end
    
    // Output stage with valid signal for downstream modules
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b0001;         // Reset to initial state
            valid_out <= 1'b0;    // Reset valid signal
        end
        else if (stage3_valid) begin
            q <= stage3_q;        // Update output when pipeline is valid
            valid_out <= 1'b1;    // Indicate valid data
        end
        else begin
            valid_out <= 1'b0;    // No valid data
        end
    end
endmodule