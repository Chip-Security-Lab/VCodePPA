//SystemVerilog
module FsmMux #(parameter DW=4) (
    input clk, rst,
    input [1:0] cmd,
    output reg [DW-1:0] data
);

// State encoding with parameters
parameter IDLE = 2'b00;
parameter CH0 = 2'b01;
parameter CH1 = 2'b10;

reg [1:0] state;
reg [1:0] cmd_reg;

// Register the input command to move the register after the input and before the state transition logic
always @(posedge clk) begin
    if (rst)
        cmd_reg <= 2'b00;
    else
        cmd_reg <= cmd;
end

// State transition logic using registered cmd_reg
reg [1:0] next_state;
always @(*) begin
    case(state)
        IDLE: next_state = (cmd_reg[0]) ? CH0 : CH1;
        CH0:  next_state = (cmd_reg[1]) ? CH1 : IDLE;
        CH1:  next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// State update
always @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= next_state;
end

// Booth Multiplier for 2-bit operands
function [3:0] booth_mult_2bit;
    input [1:0] multiplicand;
    input [1:0] multiplier;
    reg [3:0] booth_result;
    reg [2:0] booth_code;
    reg [3:0] partial_prod;
    integer i;
    begin
        booth_result = 4'b0000;
        booth_code = {multiplier, 1'b0}; // {y1, y0, 0}
        for (i=0; i<2; i=i+1) begin
            case (booth_code[1:0])
                2'b01: partial_prod = {{2{multiplicand[1]}}, multiplicand}; // +M
                2'b10: partial_prod = (~{{2{multiplicand[1]}}, multiplicand} + 1'b1); // -M
                default: partial_prod = 4'b0000;
            endcase
            booth_result = booth_result + (partial_prod << i);
            booth_code = booth_code >> 1;
        end
        booth_mult_2bit = booth_result;
    end
endfunction

// Output logic
reg [DW-1:0] data_comb;
always @(*) begin
    case(state)
        CH0: data_comb = booth_mult_2bit(2'b01, 2'b01); // Example: 1 x 1
        CH1: data_comb = booth_mult_2bit(2'b10, 2'b10); // Example: 2 x 2
        default: data_comb = 4'b0000;
    endcase
end

// Register the output to balance the delay path and improve timing
always @(posedge clk) begin
    if (rst)
        data <= {DW{1'b0}};
    else
        data <= data_comb;
end

endmodule