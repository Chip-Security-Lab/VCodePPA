//SystemVerilog
module ITRC_FSM_MultiEvent #(
    parameter EVENTS = 4
)(
    input clk,
    input rst_n,
    input [EVENTS-1:0] event_in,
    output reg [EVENTS-1:0] ack
);
    // Gray code encoding for states
    parameter IDLE = 3'b000;
    parameter CAPTURE = 3'b001;
    parameter PROCESS = 3'b011;
    
    reg [2:0] curr_state;
    reg [2:0] next_state;
    reg [2:0] state_buffer;
    reg [EVENTS-1:0] ack_buffer;
    
    // State transition logic
    always @(*) begin
        case(curr_state)
            IDLE: next_state = (|event_in) ? CAPTURE : IDLE;
            CAPTURE: next_state = PROCESS;
            PROCESS: next_state = (|event_in) ? PROCESS : IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(*) begin
        case(curr_state)
            CAPTURE: ack_buffer = event_in;
            default: ack_buffer = 0;
        endcase
    end
    
    // Sequential logic with buffering
    always @(posedge clk) begin
        if (!rst_n) begin
            curr_state <= IDLE;
            state_buffer <= IDLE;
            ack <= 0;
        end else begin
            state_buffer <= next_state;
            curr_state <= state_buffer;
            ack <= ack_buffer;
        end
    end
endmodule