//SystemVerilog
module vending_machine(
    input wire clk, rst,
    input wire [1:0] coin,
    output wire dispense
);

    wire [4:0] state, next_state;
    wire [4:0] accumulated_value;
    wire dispense_condition;

    // State register module
    state_register state_reg_inst(
        .clk(clk),
        .rst(rst),
        .next_state(next_state),
        .state(state)
    );

    // Accumulation logic module
    accumulation_logic acc_logic_inst(
        .state(state),
        .coin(coin),
        .next_state(next_state)
    );

    // Dispense control module
    dispense_control disp_ctrl_inst(
        .state(state),
        .coin(coin),
        .dispense(dispense)
    );

endmodule

module state_register(
    input wire clk,
    input wire rst,
    input wire [4:0] next_state,
    output reg [4:0] state
);

    always @(posedge clk or posedge rst)
        if (rst) state <= 5'd0;
        else state <= next_state;

endmodule

module accumulation_logic(
    input wire [4:0] state,
    input wire [1:0] coin,
    output reg [4:0] next_state
);

    always @(*) begin
        casez ({state, coin})
            {5'd0, 2'b01}: next_state = 5'd5;
            {5'd0, 2'b10}: next_state = 5'd10;
            {5'd0, 2'b11}: next_state = 5'd25;
            {5'd5, 2'b01}: next_state = 5'd10;
            {5'd5, 2'b10}: next_state = 5'd15;
            {5'd5, 2'b11}: next_state = 5'd30;
            {5'd10, 2'b01}: next_state = 5'd15;
            {5'd10, 2'b10}: next_state = 5'd20;
            {5'd10, 2'b11}: next_state = 5'd0;
            {5'd15, 2'b01}: next_state = 5'd20;
            {5'd15, 2'b10}: next_state = 5'd25;
            {5'd15, 2'b11}: next_state = 5'd0;
            {5'd20, 2'b??}: next_state = 5'd0;
            {5'd25, 2'b??}: next_state = 5'd0;
            {5'd30, 2'b??}: next_state = 5'd0;
            default: next_state = state;
        endcase
    end

endmodule

module dispense_control(
    input wire [4:0] state,
    input wire [1:0] coin,
    output reg dispense
);

    always @(*) begin
        dispense = 1'b0;
        if ((state >= 5'd20 && state < 5'd30 && coin != 2'b00) ||
            (state >= 5'd30)) dispense = 1'b1;
    end

endmodule