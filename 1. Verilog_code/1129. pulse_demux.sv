module pulse_demux (
    input wire clk,                      // System clock
    input wire pulse_in,                 // Input pulse
    input wire [1:0] route_sel,          // Routing selection
    output reg [3:0] pulse_out           // Output pulses
);
    reg pulse_detected;                  // Pulse detection register
    
    always @(posedge clk) begin
        // Edge detection for input pulse
        pulse_detected <= pulse_in;
        
        // Distribute pulse to selected output
        pulse_out <= 4'b0;
        if (pulse_in && !pulse_detected)
            pulse_out[route_sel] <= 1'b1;
    end
endmodule