module ITRC_FSM_MultiEvent #(
    parameter EVENTS = 4
)(
    input clk,
    input rst_n,
    input [EVENTS-1:0] event_in,
    output reg [EVENTS-1:0] ack
);
    // Define states as parameters instead of enum
    parameter IDLE = 2'b00;
    parameter CAPTURE = 2'b01;
    parameter PROCESS = 2'b10;
    
    reg [1:0] curr_state;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            curr_state <= IDLE;
            ack <= 0;
        end else begin
            case(curr_state)
                IDLE: if (|event_in) curr_state <= CAPTURE;
                CAPTURE: begin
                    ack <= event_in;
                    curr_state <= PROCESS;
                end
                PROCESS: begin
                    ack <= 0;
                    if (!(|event_in)) curr_state <= IDLE;
                end
                default: curr_state <= IDLE;
            endcase
        end
    end
endmodule