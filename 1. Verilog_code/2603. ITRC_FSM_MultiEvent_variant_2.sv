//SystemVerilog
module ITRC_FSM_MultiEvent #(
    parameter EVENTS = 4
)(
    input clk,
    input rst_n,
    input [EVENTS-1:0] event_in,
    output reg [EVENTS-1:0] ack
);

    // One-hot encoded states
    parameter IDLE    = 3'b001;
    parameter CAPTURE = 3'b010;
    parameter PROCESS = 3'b100;
    
    reg [2:0] curr_state;
    reg [2:0] next_state;
    
    // LUT for state transitions
    reg [2:0] state_lut [0:7];
    reg [EVENTS-1:0] ack_lut [0:7];
    
    // Initialize LUTs
    initial begin
        // IDLE state transitions
        state_lut[IDLE] = CAPTURE;
        ack_lut[IDLE] = 0;
        
        // CAPTURE state transitions
        state_lut[CAPTURE] = PROCESS;
        ack_lut[CAPTURE] = event_in;
        
        // PROCESS state transitions
        state_lut[PROCESS] = IDLE;
        ack_lut[PROCESS] = 0;
        
        // Default transitions
        state_lut[3'b000] = IDLE;
        state_lut[3'b011] = IDLE;
        state_lut[3'b101] = IDLE;
        state_lut[3'b110] = IDLE;
        state_lut[3'b111] = IDLE;
        ack_lut[3'b000] = 0;
        ack_lut[3'b011] = 0;
        ack_lut[3'b101] = 0;
        ack_lut[3'b110] = 0;
        ack_lut[3'b111] = 0;
    end
    
    // State transition logic
    always @(posedge clk) begin
        if (!rst_n) begin
            curr_state <= IDLE;
            ack <= 0;
        end else begin
            curr_state <= next_state;
            ack <= ack_lut[curr_state];
        end
    end
    
    // Next state logic
    always @(*) begin
        case(curr_state)
            IDLE: 
                next_state = (|event_in) ? state_lut[IDLE] : IDLE;
            CAPTURE:
                next_state = state_lut[CAPTURE];
            PROCESS:
                next_state = (|event_in) ? PROCESS : state_lut[PROCESS];
            default:
                next_state = state_lut[curr_state];
        endcase
    end
    
endmodule