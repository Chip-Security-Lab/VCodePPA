//SystemVerilog
module divider_4bit_with_overflow (
    input wire clk,
    input wire rst_n,
    input wire [3:0] dividend,
    input wire [3:0] divisor,
    output reg [3:0] quotient,
    output reg [3:0] remainder,
    output reg overflow
);

    // Pipeline stage 1: Input registers
    reg [3:0] dividend_reg;
    reg [3:0] divisor_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 4'b0;
            divisor_reg <= 4'b0;
        end else begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
        end
    end

    // Pipeline stage 1: Zero detection
    reg zero_divisor;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zero_divisor <= 1'b0;
        end else begin
            zero_divisor <= (divisor == 4'b0);
        end
    end

    // Pipeline stage 2: Division computation
    reg [3:0] quotient_temp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_temp <= 4'b0;
        end else begin
            quotient_temp <= zero_divisor ? 4'b0 : (dividend_reg / divisor_reg);
        end
    end

    // Pipeline stage 2: Remainder computation
    reg [3:0] remainder_temp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remainder_temp <= 4'b0;
        end else begin
            remainder_temp <= zero_divisor ? 4'b0 : (dividend_reg % divisor_reg);
        end
    end

    // Pipeline stage 3: Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 4'b0;
            remainder <= 4'b0;
        end else begin
            quotient <= quotient_temp;
            remainder <= remainder_temp;
        end
    end

    // Pipeline stage 3: Overflow flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overflow <= 1'b0;
        end else begin
            overflow <= zero_divisor;
        end
    end

endmodule