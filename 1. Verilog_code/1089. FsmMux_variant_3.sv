//SystemVerilog
module FsmMux #(parameter DW=4) (
    input clk, rst,
    input [1:0] cmd,
    output reg [DW-1:0] data
);

// One-hot state encoding
localparam IDLE = 3'b001;
localparam CH0  = 3'b010;
localparam CH1  = 3'b100;

reg [2:0] current_state, next_state;
reg [1:0] cmd_reg;

// Registered command for timing optimization
always @(posedge clk) begin
    if (rst)
        cmd_reg <= 2'b00;
    else
        cmd_reg <= cmd;
end

// Next state logic (one-hot)
always @(*) begin
    case (current_state)
        IDLE: begin
            if (cmd_reg[0])
                next_state = CH0;
            else
                next_state = CH1;
        end
        CH0: begin
            if (cmd_reg[1])
                next_state = CH1;
            else
                next_state = IDLE;
        end
        CH1: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

// State register
always @(posedge clk) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// Output logic
always @(*) begin
    case (current_state)
        CH0: data = 4'b0001;
        CH1: data = 4'b1000;
        default: data = 4'b0000;
    endcase
end

endmodule