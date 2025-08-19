module lpf_signal_recovery #(
    parameter WIDTH = 12,
    parameter ALPHA = 4 // Alpha/16 portion of new sample
)(
    input wire clock,
    input wire reset,
    input wire [WIDTH-1:0] raw_sample,
    output reg [WIDTH-1:0] filtered
);
    wire [WIDTH+4:0] new_filtered;
    
    // First-order IIR filter: y[n] = (1-alpha)*y[n-1] + alpha*x[n]
    assign new_filtered = ((16-ALPHA) * filtered + ALPHA * raw_sample) >> 4;
    
    always @(posedge clock) begin
        if (reset)
            filtered <= 0;
        else
            filtered <= new_filtered[WIDTH-1:0];
    end
endmodule