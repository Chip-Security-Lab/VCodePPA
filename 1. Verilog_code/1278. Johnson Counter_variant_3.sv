//SystemVerilog
module johnson_counter(
    input wire clk,
    input wire reset,
    input wire req,      // Request signal (replaces valid)
    output reg ack,      // Acknowledge signal (replaces ready)
    output reg [3:0] q
);
    // Internal state for handshake protocol
    reg state;
    
    // State definitions
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    
    // State machine and counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 4'b0000;
            ack <= 1'b0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        // Process data when request is received
                        q <= {q[2:0], ~q[3]}; // Johnson counter shift logic
                        ack <= 1'b1;          // Acknowledge the request
                        state <= BUSY;
                    end
                end
                
                BUSY: begin
                    if (!req) begin
                        // Reset acknowledge when request is lowered
                        ack <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule