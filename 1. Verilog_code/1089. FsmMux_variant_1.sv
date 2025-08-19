//SystemVerilog
module FsmMux #(parameter DW=4) (
    input clk, rst,
    input [1:0] cmd,
    output reg [DW-1:0] data
);

    // State encoding with parameters
    parameter IDLE = 2'b00;
    parameter CH0  = 2'b01;
    parameter CH1  = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    // Baugh-Wooley multiplier output
    wire [3:0] bw_mult_result;

    // State transition logic
    always @(*) begin : state_transition_logic
        case(state)
            IDLE: next_state = (cmd[0]) ? CH0 : CH1;
            CH0:  next_state = (cmd[1]) ? CH1 : IDLE;
            CH1:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // State register update
    always @(posedge clk) begin : state_register_update
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Output logic for data
    always @(*) begin : output_logic_data
        case(state)
            CH0: data = bw_mult_result;
            CH1: data = 4'b1000;
            default: data = 4'b0000;
        endcase
    end

    // Baugh-Wooley multiplier instantiation for 2-bit signed multiplication
    BaughWooley2x2 bw_mult_inst (
        .a(cmd[1:0]),
        .b(2'b10),
        .product(bw_mult_result)
    );

endmodule

module BaughWooley2x2 (
    input  [1:0] a,
    input  [1:0] b,
    output [3:0] product
);

    wire a0, a1, b0, b1;
    wire pp0, pp1, pp2, pp3, pp4, pp5;
    wire sum1, carry1;
    wire sum2, carry2;

    assign a0 = a[0];
    assign a1 = a[1];
    assign b0 = b[0];
    assign b1 = b[1];

    // Partial products
    assign pp0 = a0 & b0;
    assign pp1 = a0 & b1;
    assign pp2 = a1 & b0;
    assign pp3 = ~(a1 & b1);
    assign pp4 = a1;
    assign pp5 = b1;

    assign sum1   = pp1 ^ pp2;
    assign carry1 = pp1 & pp2;

    assign sum2   = carry1 ^ pp3 ^ pp4 ^ pp5;
    assign carry2 = (carry1 & pp3) | (carry1 & pp4) | (carry1 & pp5) |
                    (pp3 & pp4)   | (pp3 & pp5)   | (pp4 & pp5);

    assign product[0] = pp0;
    assign product[1] = sum1;
    assign product[2] = sum2;
    assign product[3] = ~carry2;

endmodule