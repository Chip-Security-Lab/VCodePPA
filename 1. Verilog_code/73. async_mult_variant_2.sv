//SystemVerilog
module async_mult (
    input [3:0] A, B,
    output [7:0] P,
    input start,
    output done
);

    parameter IDLE = 3'b000;
    parameter INIT = 3'b001; 
    parameter ADD = 3'b010;
    parameter SHIFT = 3'b011;
    parameter FINISH = 3'b100;

    reg [2:0] state, next_state;
    reg [3:0] multiplicand;
    reg [3:0] multiplier;
    reg [7:0] product;
    reg done_reg;
    reg [2:0] counter;

    // State transition logic - separated into current and next state
    always @(*) begin
        case(state)
            IDLE: next_state = start ? INIT : IDLE;
            INIT: next_state = ADD;
            ADD: next_state = SHIFT;
            SHIFT: next_state = (counter == 3'b011) ? FINISH : ADD;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // State register - using non-blocking assignment for sequential logic
    always @(posedge start or posedge done_reg) begin
        if (done_reg)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Counter control - simplified logic
    always @(posedge start or posedge done_reg) begin
        if (done_reg)
            counter <= 3'b000;
        else if (state == SHIFT)
            counter <= counter + 1'b1;
    end

    // Done signal control - simplified logic
    always @(posedge start or posedge done_reg) begin
        if (done_reg)
            done_reg <= 1'b1;
        else if (state == INIT)
            done_reg <= 1'b0;
    end

    // Multiplicand and multiplier initialization
    always @(posedge start) begin
        if (state == INIT) begin
            multiplicand <= A;
            multiplier <= B;
        end
    end

    // Product calculation - initialization
    always @(posedge start) begin
        if (state == INIT)
            product <= 8'b0;
    end

    // Product calculation - addition
    always @(posedge start) begin
        if (state == ADD)
            product <= multiplier[0] ? {product[7:4] + multiplicand, product[3:0]} : product;
    end

    // Product calculation - shift
    always @(posedge start) begin
        if (state == SHIFT)
            product <= product >> 1;
    end

    // Multiplier shift
    always @(posedge start) begin
        if (state == SHIFT)
            multiplier <= multiplier >> 1;
    end

    assign P = product;
    assign done = done_reg;

endmodule