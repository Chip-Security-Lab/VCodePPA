//SystemVerilog
module johnson_counter(
    input wire clk,
    input wire reset,
    input wire valid,     // Valid signal (was req)
    input wire ready,     // Ready signal (was ack output)
    output reg [3:0] q
);
    
    reg valid_d;          // Delayed valid for edge detection
    reg busy;             // Indicates counter is processing
    wire handshake;       // Successful handshake signal
    
    // Edge detection for valid signal
    always @(posedge clk) begin
        if (reset)
            valid_d <= 1'b0;
        else
            valid_d <= valid;
    end
    
    // Handshake occurs when both valid and ready are high
    assign handshake = valid && ready;
    
    // Counter logic with valid-ready handshake
    always @(posedge clk) begin
        if (reset) begin
            q <= 4'b0000;
            busy <= 1'b0;
        end
        else begin
            if (handshake && !busy) begin
                // Valid data and receiver is ready
                q <= {q[2:0], ~q[3]}; // Feed inverted MSB to LSB
                busy <= 1'b1;         // Set busy flag
            end
            else if (busy && !valid) begin
                // Valid deasserted, transaction complete
                busy <= 1'b0;
            end
        end
    end
endmodule