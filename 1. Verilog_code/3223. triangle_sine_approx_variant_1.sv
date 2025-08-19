//SystemVerilog
module triangle_sine_approx(
    input clk,
    input reset,
    input req,           // Request signal (replaces valid)
    input [7:0] data_in, // Input data
    output reg [7:0] sine_out,
    output reg ack       // Acknowledge signal (replaces ready)
);
    reg [7:0] triangle;
    reg up_down;
    reg processing;      // Flag to indicate processing state
    reg [1:0] state;     // State machine
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // Req-Ack handshake and processing state machine
    always @(posedge clk) begin
        if (reset) begin
            triangle <= 8'd0;
            up_down <= 1'b1;
            ack <= 1'b0;
            processing <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (req && !ack) begin
                        processing <= 1'b1;
                        state <= PROCESS;
                    end
                    ack <= 1'b0;
                end
                
                PROCESS: begin
                    // Generate triangle wave
                    if (up_down) begin
                        if (triangle == 8'd255)
                            up_down <= 1'b0;
                        else
                            triangle <= triangle + 8'd1;
                    end else begin
                        if (triangle == 8'd0)
                            up_down <= 1'b1;
                        else
                            triangle <= triangle - 8'd1;
                    end
                    
                    // Process is complete
                    state <= COMPLETE;
                end
                
                COMPLETE: begin
                    ack <= 1'b1;
                    processing <= 1'b0;
                    
                    // Wait for req to be deasserted before going back to IDLE
                    if (!req)
                        state <= IDLE;
                end
                
                default:
                    state <= IDLE;
            endcase
        end
    end
    
    // Apply a simple cubic-like transformation to triangle to approximate sine
    always @(posedge clk) begin
        if (reset) begin
            sine_out <= 8'd0;
        end else if (state == PROCESS || state == COMPLETE) begin
            if (triangle < 8'd64)
                sine_out <= 8'd64 + (triangle >> 1);
            else if (triangle < 8'd192)
                sine_out <= 8'd96 + (triangle >> 1);
            else
                sine_out <= 8'd192 + (triangle >> 2);
        end
    end
endmodule