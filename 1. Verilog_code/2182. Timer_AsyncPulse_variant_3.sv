//SystemVerilog
//IEEE 1364-2005 Verilog
module Timer_AsyncPulse (
    input wire clk,
    input wire rst,
    
    // Input interface with ready-valid handshake
    input wire start_valid,
    output reg start_ready,
    
    // Output interface with ready-valid handshake
    output reg pulse_valid,
    input wire pulse_ready
);
    reg [3:0] cnt;
    wire target_reached;
    reg processing;
    
    // Optimize comparison with constant check
    assign target_reached = (cnt == 4'hF);
    
    // FSM state control - combine handshaking logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_ready <= 1'b1;
            processing <= 1'b0;
            pulse_valid <= 1'b0;
            cnt <= 4'd0;
        end else begin
            // Input handshake handling
            if (start_valid && start_ready) begin
                start_ready <= 1'b0;
                processing <= 1'b1;
                cnt <= 4'd1; // Initialize counter on handshake
            end
            
            // Counter increment during processing
            else if (processing && !target_reached) begin
                cnt <= cnt + 4'd1;
            end
            
            // Target reached - generate pulse
            else if (processing && target_reached && !pulse_valid) begin
                pulse_valid <= 1'b1;
            end
            
            // Output handshake completion
            else if (pulse_valid && pulse_ready) begin
                pulse_valid <= 1'b0;
                processing <= 1'b0;
                start_ready <= 1'b1;
                cnt <= 4'd0;
            end
        end
    end
endmodule