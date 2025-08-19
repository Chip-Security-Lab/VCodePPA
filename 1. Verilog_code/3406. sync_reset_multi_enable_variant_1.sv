//SystemVerilog
// Top level module
module sync_reset_multi_enable (
    input  wire       clk,
    input  wire       reset_in,
    input  wire [3:0] enable_conditions,
    output wire [3:0] reset_out
);
    // Internal signals to connect submodules
    wire       reset_sync;
    wire [3:0] channel_resets;
    
    // Reset synchronizer submodule instance
    reset_synchronizer u_reset_sync (
        .clk       (clk),
        .reset_in  (reset_in),
        .reset_out (reset_sync)
    );
    
    // Channel-specific reset controllers
    channel_reset_controller u_channel_reset (
        .clk               (clk),
        .sync_reset        (reset_sync),
        .enable_conditions (enable_conditions),
        .channel_resets    (channel_resets)
    );
    
    // Output assignment - directly connect to reduce one level of logic
    assign reset_out = channel_resets;
    
endmodule

// Reset synchronizer module with improved metastability handling
module reset_synchronizer (
    input  wire clk,
    input  wire reset_in,
    output reg  reset_out
);
    // Two-stage synchronizer for better metastability handling
    (* dont_touch = "true" *) reg reset_meta;
    
    always @(posedge clk) begin
        reset_meta <= reset_in;     // First stage synchronizer
        reset_out  <= reset_meta;   // Second stage synchronizer
    end
endmodule

// Optimized channel-specific reset controller
module channel_reset_controller (
    input  wire       clk,
    input  wire       sync_reset,
    input  wire [3:0] enable_conditions,
    output reg  [3:0] channel_resets
);
    // Pre-compute the next state for each channel to reduce critical path
    reg [3:0] next_channel_resets;
    
    // Compute next state combinationally - balanced path algorithm
    always @(*) begin
        // Default case: keep current state
        next_channel_resets = channel_resets;
        
        if (sync_reset) begin
            // Reset condition - all channels set to 1
            next_channel_resets = 4'b1111;
        end else begin
            // Split logic into multiple simple operations to balance paths
            // Channel 0
            if (enable_conditions[0])
                next_channel_resets[0] = 1'b0;
                
            // Channel 1
            if (enable_conditions[1])
                next_channel_resets[1] = 1'b0;
                
            // Channel 2
            if (enable_conditions[2])
                next_channel_resets[2] = 1'b0;
                
            // Channel 3
            if (enable_conditions[3])
                next_channel_resets[3] = 1'b0;
        end
    end
    
    // Sequential logic to update registers
    always @(posedge clk) begin
        channel_resets <= next_channel_resets;
    end
endmodule