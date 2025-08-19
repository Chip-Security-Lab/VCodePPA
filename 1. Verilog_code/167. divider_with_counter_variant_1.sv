//SystemVerilog
module divider_with_counter (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline stage 1: Input and initialization
    reg [7:0] dividend_reg;
    reg [7:0] divisor_reg;
    reg [3:0] cycle_count_reg;
    reg [7:0] partial_remainder_reg;
    reg [7:0] temp_quotient_reg;
    reg [2:0] bit_position_reg;

    // Pipeline stage 2: Division computation
    reg [7:0] shifted_divisor_reg;
    reg [7:0] partial_remainder_next;
    reg [7:0] temp_quotient_next;
    reg [2:0] bit_position_next;

    // Pipeline stage 3: Result computation
    reg [7:0] quotient_next;
    reg [7:0] remainder_next;

    // Stage 1: Input and initialization
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dividend_reg <= 0;
            divisor_reg <= 0;
            cycle_count_reg <= 0;
            partial_remainder_reg <= 0;
            temp_quotient_reg <= 0;
            bit_position_reg <= 0;
        end else begin
            if (cycle_count_reg == 0) begin
                dividend_reg <= a;
                divisor_reg <= b;
                partial_remainder_reg <= 0;
                temp_quotient_reg <= 0;
                bit_position_reg <= 7;
                cycle_count_reg <= cycle_count_reg + 1;
            end else begin
                partial_remainder_reg <= partial_remainder_next;
                temp_quotient_reg <= temp_quotient_next;
                bit_position_reg <= bit_position_next;
                cycle_count_reg <= cycle_count_reg + 1;
            end
        end
    end

    // Stage 2: Division computation
    always @(*) begin
        shifted_divisor_reg = divisor_reg << bit_position_reg;
        if (partial_remainder_reg + shifted_divisor_reg <= dividend_reg) begin
            partial_remainder_next = partial_remainder_reg + shifted_divisor_reg;
            temp_quotient_next = temp_quotient_reg | (1 << bit_position_reg);
        end else begin
            partial_remainder_next = partial_remainder_reg;
            temp_quotient_next = temp_quotient_reg;
        end
        bit_position_next = bit_position_reg - 1;
    end

    // Stage 3: Result computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else begin
            if (cycle_count_reg == 9) begin
                quotient <= temp_quotient_reg;
                remainder <= dividend_reg - partial_remainder_reg;
            end
        end
    end

endmodule