//SystemVerilog
module mixed_precision_mult (
    input [7:0] A,
    input [3:0] B,
    output [11:0] Result
);

    reg [11:0] booth_result;
    reg [11:0] partial_product;
    reg [3:0] booth_counter;
    reg [7:0] multiplicand;
    reg [3:0] multiplier;
    reg [1:0] booth_bits;
    reg [11:0] booth_result_next;
    reg [11:0] partial_product_next;
    reg [1:0] state;
    reg [1:0] next_state;
    
    localparam IDLE = 2'b00;
    localparam ENCODE = 2'b01;
    localparam ACCUM = 2'b10;
    localparam DONE = 2'b11;

    // State register
    always @(*) begin
        state = IDLE;
        next_state = IDLE;
        
        case (state)
            IDLE: next_state = ENCODE;
            ENCODE: next_state = ACCUM;
            ACCUM: next_state = (booth_counter == 3) ? DONE : ENCODE;
            DONE: next_state = IDLE;
        endcase
    end

    // Input register stage
    always @(*) begin
        if (state == IDLE) begin
            multiplicand = A;
            multiplier = B;
        end
    end

    // Booth encoding stage
    always @(*) begin
        if (state == ENCODE) begin
            booth_bits = {multiplier[booth_counter], booth_counter > 0 ? multiplier[booth_counter-1] : 1'b0};
        end
    end

    // Partial product generation stage
    always @(*) begin
        if (state == ENCODE) begin
            case (booth_bits)
                2'b00: partial_product_next = 12'b0;
                2'b01: partial_product_next = multiplicand << booth_counter;
                2'b10: partial_product_next = (~multiplicand + 1'b1) << booth_counter;
                2'b11: partial_product_next = 12'b0;
            endcase
        end
    end

    // Accumulation stage
    always @(*) begin
        if (state == ACCUM) begin
            booth_result_next = booth_result + partial_product;
        end
    end

    // Counter and result update
    always @(*) begin
        if (state == IDLE) begin
            booth_counter = 0;
            booth_result = 12'b0;
            partial_product = 12'b0;
        end
        else if (state == ACCUM) begin
            booth_counter = booth_counter + 1;
            booth_result = booth_result_next;
            partial_product = partial_product_next;
        end
    end

    assign Result = (state == DONE) ? booth_result : 12'b0;

endmodule