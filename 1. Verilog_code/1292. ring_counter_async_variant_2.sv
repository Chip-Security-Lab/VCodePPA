//SystemVerilog
module ring_counter_async (
    input clk, rst_n,
    input req,          // Request signal (replacing en)
    output reg ack,     // Acknowledge signal
    output reg [3:0] ring_pattern
);

    // Internal state
    reg req_prev;
    wire req_edge;
    
    // Edge detection logic
    assign req_edge = req && !req_prev;
    
    // Store previous request value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_prev <= 1'b0;
        end
        else begin
            req_prev <= req;
        end
    end
    
    // Ring pattern shifting logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_pattern <= 4'b0001;  // Initialize to a one-hot pattern
        end
        else if (req_edge) begin
            ring_pattern <= {ring_pattern[2:0], ring_pattern[3]}; // Shift left
        end
    end
    
    // Acknowledge signal control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
        end
        else if (req_edge) begin
            ack <= 1'b1;
        end
        else if (!req && req_prev) begin
            ack <= 1'b0;
        end
    end
    
endmodule