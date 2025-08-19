//SystemVerilog
module async_reset_ring_counter(
    input wire clk,
    input wire rst_n, // Active-low reset
    input wire req,   // Request signal
    output reg ack,   // Acknowledge signal
    output reg [3:0] q
);
    // Edge detection for request signal
    reg req_r;
    wire req_edge;
    
    // Detect rising edge of request signal
    assign req_edge = req & ~req_r;
    
    // Detect falling edge of request signal
    wire req_fall;
    assign req_fall = ~req & req_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b0001; // Reset to initial state
            ack <= 1'b0;  // Reset acknowledge signal
            req_r <= 1'b0; // Reset internal request register
        end else begin
            // Register the request signal
            req_r <= req;
            
            // State transitions based on edge detection
            if (req_edge) begin
                // Use bit-wise operations for more efficient circular shift
                q <= {q[2:0], q[3]}; // Circular shift when request received
                ack <= 1'b1;
            end else if (req_fall) begin
                ack <= 1'b0; // Clear acknowledge when request is deasserted
            end
        end
    end
endmodule