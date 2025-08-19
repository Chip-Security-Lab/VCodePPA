module mult_4bit(
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] prod,
    output reg prod_valid
);

    reg [3:0] a_reg;
    reg [3:0] b_reg;
    wire [3:0] partial_prod [3:0];
    wire [7:0] sum_stage1 [1:0];
    wire [7:0] sum_stage2;
    reg [1:0] state;
    reg [1:0] next_state;

    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: next_state = valid ? CALC : IDLE;
            CALC: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b1;
            prod_valid <= 1'b0;
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    prod_valid <= 1'b0;
                    if (valid) begin
                        a_reg <= a;
                        b_reg <= b;
                    end
                end
                CALC: begin
                    ready <= 1'b0;
                    prod_valid <= 1'b0;
                end
                DONE: begin
                    ready <= 1'b0;
                    prod_valid <= 1'b1;
                end
            endcase
        end
    end

    // Partial product generation
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pp_gen
            assign partial_prod[i] = a_reg & {4{b_reg[i]}};
        end
    endgenerate

    // First stage addition
    adder_8bit adder1(
        .a({4'b0, partial_prod[0]}),
        .b({3'b0, partial_prod[1], 1'b0}),
        .sum(sum_stage1[0])
    );

    adder_8bit adder2(
        .a({2'b0, partial_prod[2], 2'b0}),
        .b({1'b0, partial_prod[3], 3'b0}),
        .sum(sum_stage1[1])
    );

    // Final addition
    adder_8bit adder3(
        .a(sum_stage1[0]),
        .b(sum_stage1[1]),
        .sum(sum_stage2)
    );

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod <= 8'b0;
        end else if (state == CALC) begin
            prod <= sum_stage2;
        end
    end

endmodule

module adder_8bit(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    assign sum = a + b;
endmodule