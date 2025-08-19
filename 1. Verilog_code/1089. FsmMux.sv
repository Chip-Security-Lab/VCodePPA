module FsmMux #(parameter DW=4) (
    input clk, rst,
    input [1:0] cmd,
    output reg [DW-1:0] data
);

// State encoding with parameters
parameter IDLE = 2'b00;
parameter CH0 = 2'b01;
parameter CH1 = 2'b10;

reg [1:0] state, next_state;

// State transition logic
always @(*) begin
    case(state)
        IDLE: next_state = (cmd[0]) ? CH0 : CH1;
        CH0:  next_state = (cmd[1]) ? CH1 : IDLE;
        CH1:  next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// State update
always @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= next_state;
end

// Output logic
always @(*) begin
    case(state)
        CH0: data = 4'b0001;
        CH1: data = 4'b1000;
        default: data = 4'b0000;
    endcase
end

endmodule