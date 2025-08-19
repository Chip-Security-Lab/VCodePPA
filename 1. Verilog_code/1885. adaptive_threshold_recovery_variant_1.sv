//SystemVerilog
module adaptive_threshold_recovery (
    input wire clk,
    input wire reset,
    input wire [7:0] signal_in,
    input wire [7:0] noise_level,
    output reg [7:0] signal_out,
    output reg signal_valid
);
    // Pipeline stage registers
    reg [7:0] signal_in_reg;
    reg [7:0] noise_level_reg;
    reg [7:0] threshold_reg;
    reg [7:0] threshold_computed;
    
    // Reset synchronization registers with reduced fanout
    (* dont_touch = "true" *) reg reset_meta, reset_sync;
    
    // Two-FF synchronizer for reset to avoid metastability
    always @(posedge clk) begin
        reset_meta <= reset;
        reset_sync <= reset_meta;
    end
    
    // Pipeline stage 1: Input registration and optimized threshold computation
    always @(posedge clk) begin
        if (reset_sync) begin
            signal_in_reg <= 8'd0;
            noise_level_reg <= 8'd0;
            threshold_computed <= 8'd128;
        end else begin
            signal_in_reg <= signal_in;
            noise_level_reg <= noise_level;
            // Use shift and add for multiplication (64 + noise_level/2)
            threshold_computed <= {1'b1, 6'b000000, 1'b0} + {1'b0, noise_level_reg[7:1]};
        end
    end
    
    // Pipeline stage 2: Threshold registration and optimized signal comparison
    always @(posedge clk) begin
        if (reset_sync) begin
            threshold_reg <= 8'd128;
            signal_out <= 8'd0;
            signal_valid <= 1'b0;
        end else begin
            threshold_reg <= threshold_computed;
            
            // Optimized threshold comparison using single comparison
            // This reduces logic depth and improves timing
            signal_valid <= (signal_in_reg > threshold_reg);
            signal_out <= signal_valid ? signal_in_reg : 8'd0;
        end
    end
endmodule