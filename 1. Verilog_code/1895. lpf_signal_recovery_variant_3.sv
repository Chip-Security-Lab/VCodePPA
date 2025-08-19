//SystemVerilog
module lpf_signal_recovery #(
    parameter WIDTH = 12,
    parameter ALPHA = 4 // Alpha/16 portion of new sample
)(
    input wire clock,
    input wire reset,
    input wire [WIDTH-1:0] raw_sample,
    output reg [WIDTH-1:0] filtered
);
    // Pre-compute the alpha and (16-alpha) terms to reduce critical path
    wire [3:0] alpha_term = ALPHA;
    wire [3:0] one_minus_alpha_term = 16 - ALPHA;
    
    // Split the multiplication and addition operations to balance path delay
    reg [WIDTH+3:0] alpha_times_raw;       // ALPHA * raw_sample
    reg [WIDTH+3:0] one_minus_alpha_times_filtered;  // (16-ALPHA) * filtered
    
    // Register intermediate results to break critical path
    always @(posedge clock) begin
        if (reset) begin
            alpha_times_raw <= 0;
            one_minus_alpha_times_filtered <= 0;
            filtered <= 0;
        end else begin
            // Calculate components in parallel
            alpha_times_raw <= raw_sample * alpha_term;
            one_minus_alpha_times_filtered <= filtered * one_minus_alpha_term;
            
            // Sum the components and shift in the final stage
            filtered <= (alpha_times_raw + one_minus_alpha_times_filtered) >> 4;
        end
    end
endmodule