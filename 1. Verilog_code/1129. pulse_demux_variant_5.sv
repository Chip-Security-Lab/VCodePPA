//SystemVerilog
//////////////////////////////////////////////////////////////////////////////////
// Module Name: pulse_demux
// Description: Pulse demultiplexer with edge detection and routing capabilities
//              Optimized with deeper pipeline stages for higher clock frequency
// Standard: IEEE 1364-2005 Verilog
//////////////////////////////////////////////////////////////////////////////////
module pulse_demux (
    input wire clk,                      // System clock
    input wire pulse_in,                 // Input pulse
    input wire [1:0] route_sel,          // Routing selection
    output reg [3:0] pulse_out           // Output pulses
);
    // Internal signals for pipeline stages
    
    // Stage 1: Input registration and initial detection
    reg pulse_in_stage1;                // Registered input pulse
    reg [1:0] route_sel_stage1;         // Registered route selection
    
    // Stage 2: Edge detection
    reg pulse_in_stage2;                // Second stage registered input
    reg pulse_detected_stage2;          // Pulse detection register
    reg [1:0] route_sel_stage2;         // Route selection passed to stage 2
    
    // Stage 3: Edge calculation and preparation
    reg pulse_edge_stage3;              // Edge detection signal
    reg [1:0] route_sel_stage3;         // Route selection passed to stage 3
    
    // Stage 4: Selector decoding preparation
    reg pulse_edge_stage4;              // Edge signal passed to stage 4
    reg [1:0] route_sel_stage4;         // Route selection passed to stage 4
    reg [3:0] decoded_sel_stage4;       // Pre-decoded selection for final stage
    
    // Stage 1: Register inputs
    always @(posedge clk) begin
        // Input registration stage
        pulse_in_stage1 <= pulse_in;
    end
    
    // Route selection registration - separated from pulse path
    always @(posedge clk) begin
        // Route selection registration stage
        route_sel_stage1 <= route_sel;
    end
    
    // Stage 2: Propagate pulse signals
    always @(posedge clk) begin
        // Pulse signal propagation
        pulse_in_stage2 <= pulse_in_stage1;
        pulse_detected_stage2 <= pulse_in_stage1;
    end
    
    // Stage 2: Propagate route selection
    always @(posedge clk) begin
        // Route selection propagation
        route_sel_stage2 <= route_sel_stage1;
    end
    
    // Stage 3: Edge detection calculation
    always @(posedge clk) begin
        // Edge detection logic
        pulse_edge_stage3 <= pulse_in_stage2 && !pulse_detected_stage2;
    end
    
    // Stage 3: Route selection propagation
    always @(posedge clk) begin
        // Route selection propagation
        route_sel_stage3 <= route_sel_stage2;
    end
    
    // Stage 4: Edge signal propagation
    always @(posedge clk) begin
        // Edge signal propagation
        pulse_edge_stage4 <= pulse_edge_stage3;
    end
    
    // Stage 4: Route selection processing
    always @(posedge clk) begin
        // Route selection propagation and decoding
        route_sel_stage4 <= route_sel_stage3;
        
        // Pre-decode the selection bits to one-hot
        decoded_sel_stage4 <= 4'b0001 << route_sel_stage3;
    end
    
    // Stage 5: Final output generation
    always @(posedge clk) begin
        // Default state
        pulse_out <= 4'b0;  
        
        // Conditional output assignment based on edge detection
        if (pulse_edge_stage4)
            pulse_out <= decoded_sel_stage4;
    end
endmodule