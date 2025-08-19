module divider_8bit_quotient_remainder (
    input clk,
    input rst_n,
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline stage 1: Input register
    reg [7:0] dividend_reg;
    reg [7:0] divisor_reg;
    
    // Pipeline stage 2: Division computation
    reg [7:0] quotient_reg;
    reg [7:0] remainder_reg;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 8'b0;
            divisor_reg <= 8'b0;
        end else begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
        end
    end
    
    // Pipeline stage 2: Division computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_reg <= 8'b0;
            remainder_reg <= 8'b0;
        end else begin
            quotient_reg <= dividend_reg / divisor_reg;
            remainder_reg <= dividend_reg % divisor_reg;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 8'b0;
            remainder <= 8'b0;
        end else begin
            quotient <= quotient_reg;
            remainder <= remainder_reg;
        end
    end

endmodule