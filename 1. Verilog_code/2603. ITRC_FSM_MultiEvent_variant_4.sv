//SystemVerilog
module ITRC_FSM_MultiEvent #(
    parameter EVENTS = 4
)(
    input clk,
    input rst_n,
    input [EVENTS-1:0] event_in,
    output reg [EVENTS-1:0] ack
);
    parameter IDLE = 2'b00;
    parameter CAPTURE = 2'b01;
    parameter PROCESS = 2'b10;
    
    reg [1:0] curr_state;
    reg [1:0] next_state;
    reg [EVENTS-1:0] event_latch;
    reg [EVENTS-1:0] event_in_reg;
    
    // Register input signals to avoid combinational loops
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            event_in_reg <= 0;
        else
            event_in_reg <= event_in;
    end
    
    // State transition logic - separated into its own always block
    always @(*) begin
        case(curr_state)
            IDLE: next_state = (|event_in_reg) ? CAPTURE : IDLE;
            CAPTURE: next_state = PROCESS;
            PROCESS: next_state = (|event_in_reg) ? PROCESS : IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // State register - separated from output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end
    
    // Event latch logic - separated into its own always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            event_latch <= 0;
        else if (curr_state == CAPTURE)
            event_latch <= event_in_reg;
    end
    
    // Output logic - separated into its own always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ack <= 0;
        else if (curr_state == CAPTURE)
            ack <= event_in_reg;
        else
            ack <= 0;
    end
endmodule