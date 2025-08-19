//SystemVerilog
module threshold_comparator(
    input clk,
    input rst,
    input [7:0] threshold,  // Programmable threshold value
    input [7:0] data_input,
    input req,              // Request signal (replaces load_threshold)
    output reg ack,         // Acknowledge signal (new)
    output reg above_threshold,
    output reg below_threshold,
    output reg at_threshold
);
    // Internal threshold register
    reg [7:0] threshold_reg;
    
    // State machine for req-ack handshake
    reg handshake_state;
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    
    // Handshake state machine logic - Flattened if-else structure
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            handshake_state <= IDLE;
            ack <= 1'b0;
            threshold_reg <= 8'h00;
        end else if (handshake_state == IDLE && req) begin
            handshake_state <= BUSY;
            threshold_reg <= threshold;
            ack <= 1'b1;
        end else if (handshake_state == BUSY && !req) begin
            handshake_state <= IDLE;
            ack <= 1'b0;
        end
    end
    
    // Comparison logic - Data vs Threshold - Flattened if-else structure
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            above_threshold <= 1'b0;
            below_threshold <= 1'b0;
            at_threshold <= 1'b0;
        end else if (handshake_state == BUSY && ack) begin
            above_threshold <= (data_input > threshold_reg);
            below_threshold <= (data_input < threshold_reg);
            at_threshold <= (data_input == threshold_reg);
        end
    end
endmodule