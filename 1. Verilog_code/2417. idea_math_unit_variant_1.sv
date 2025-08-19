//SystemVerilog
module idea_math_unit (
    input clk, mul_en,
    input [15:0] x, y,
    output reg [15:0] result
);
    reg [15:0] x_reg, y_reg;
    reg mul_en_reg;
    wire [31:0] mul_temp;
    wire [15:0] sum_temp;
    
    // Register inputs to improve timing
    always @(posedge clk) begin
        x_reg <= x;
        y_reg <= y;
        mul_en_reg <= mul_en;
    end
    
    // Addition path pre-computation
    assign sum_temp = (x_reg + y_reg) % 65536;
    
    // Instantiate Karatsuba multiplier
    karatsuba_multiplier karatsuba_inst (
        .a(x_reg),
        .b(y_reg),
        .product(mul_temp)
    );
    
    // Output computation moved after registered inputs
    always @(posedge clk) begin
        if (mul_en_reg) begin
            result <= (mul_temp == 32'h0) ? 16'hFFFF : 
                     (mul_temp % 17'h10001);
        end else begin
            result <= sum_temp;
        end
    end
endmodule

module karatsuba_multiplier (
    input [15:0] a,
    input [15:0] b,
    output [31:0] product
);
    // Split inputs into high and low halves
    wire [7:0] a_high, a_low, b_high, b_low;
    reg [15:0] z0_reg, z2_reg;
    reg [16:0] sum_products_reg;
    wire [15:0] z1;
    
    assign a_high = a[15:8];
    assign a_low = a[7:0];
    assign b_high = b[15:8];
    assign b_low = b[7:0];
    
    // Pre-compute partial products with registers
    always @(*) begin
        // z0 = a_low * b_low
        z0_reg = a_low * b_low;
        
        // z2 = a_high * b_high
        z2_reg = a_high * b_high;
        
        // Intermediate calculation for z1
        sum_products_reg = (a_low + a_high) * (b_low + b_high);
    end
    
    // z1 calculation moved after registered components
    assign z1 = sum_products_reg - z0_reg - z2_reg;
    
    // Assemble the final product: z2 << 16 + z1 << 8 + z0
    assign product = {z2_reg, 16'b0} + {8'b0, z1, 8'b0} + z0_reg;
endmodule