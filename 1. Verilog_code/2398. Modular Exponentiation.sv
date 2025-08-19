module mod_exp #(parameter WIDTH = 16) (
    input wire clk, reset,
    input wire start,
    input wire [WIDTH-1:0] base, exponent, modulus,
    output reg [WIDTH-1:0] result,
    output reg done
);
    reg [WIDTH-1:0] exp_reg, base_reg, temp;
    reg calculating;
    
    always @(posedge clk) begin
        if (reset) begin
            exp_reg <= 0;
            base_reg <= 0;
            result <= 1;
            done <= 0;
            calculating <= 0;
        end else if (start) begin
            exp_reg <= exponent;
            base_reg <= base;
            result <= 1;
            calculating <= 1;
            done <= 0;
        end else if (calculating) begin
            if (exp_reg == 0) begin
                calculating <= 0;
                done <= 1;
            end else begin
                if (exp_reg[0]) begin
                    temp = (result * base_reg) % modulus;
                    result <= temp;
                end
                base_reg <= (base_reg * base_reg) % modulus;
                exp_reg <= exp_reg >> 1;
            end
        end
    end
endmodule