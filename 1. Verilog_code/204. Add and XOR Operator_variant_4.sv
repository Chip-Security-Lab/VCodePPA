//SystemVerilog
module multiply_divide_operator (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input data_valid,
    output data_ready,
    output [15:0] product,
    output [7:0] quotient,
    output [7:0] remainder,
    output result_valid,
    input result_ready
);

    reg [7:0] a_reg, b_reg;
    reg [15:0] product_reg;
    reg [7:0] quotient_reg, remainder_reg;
    reg busy;
    reg output_valid;
    
    wire [15:0] karatsuba_product;
    wire [7:0] div_quotient;
    wire [7:0] div_remainder;
    
    assign data_ready = ~busy | (output_valid & result_ready);
    assign result_valid = output_valid;
    assign product = product_reg;
    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    
    karatsuba_multiplier km (
        .a(a_reg),
        .b(b_reg),
        .product(karatsuba_product)
    );
    
    divider div (
        .dividend(a_reg),
        .divisor(b_reg),
        .quotient(div_quotient),
        .remainder(div_remainder)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {a_reg, b_reg, product_reg, quotient_reg, remainder_reg, busy, output_valid} <= 0;
        end else begin
            if (data_valid & data_ready) begin
                a_reg <= a;
                b_reg <= b;
                busy <= 1'b1;
                output_valid <= 1'b0;
            end
            
            if (busy & ~output_valid) begin
                product_reg <= karatsuba_product;
                quotient_reg <= div_quotient;
                remainder_reg <= div_remainder;
                output_valid <= 1'b1;
            end
            
            if (output_valid & result_ready) begin
                output_valid <= 1'b0;
                busy <= 1'b0;
            end
        end
    end
endmodule

module karatsuba_multiplier (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z1, z2;
    wire [7:0] sum_a, sum_b;
    wire [7:0] prod_sum;
    wire [15:0] term1, term2, term3;
    
    assign {a_high, a_low} = a;
    assign {b_high, b_low} = b;
    
    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    
    assign sum_a = {4'b0, a_high} + {4'b0, a_low};
    assign sum_b = {4'b0, b_high} + {4'b0, b_low};
    assign prod_sum = sum_a * sum_b;
    assign z1 = prod_sum - z0 - z2;
    
    assign term1 = {z2, 8'b0};
    assign term2 = {4'b0, z1, 4'b0};
    assign term3 = {8'b0, z0};
    assign product = term1 + term2 + term3;
endmodule

module divider (
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient,
    output [7:0] remainder
);
    reg [7:0] q, r;
    integer i;
    
    always @(*) begin
        q = 0;
        r = 0;
        for (i = 7; i >= 0; i = i - 1) begin
            r = {r[6:0], dividend[i]};
            if (r >= divisor) begin
                r = r - divisor;
                q[i] = 1'b1;
            end
        end
    end
    
    assign quotient = q;
    assign remainder = r;
endmodule