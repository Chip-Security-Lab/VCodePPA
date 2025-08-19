//SystemVerilog
// Top level module
module bcd2bin #(parameter N=4)(
    input [N*4-1:0] bcd,
    output reg [N*7-1:0] bin
);
    // Intermediate signals
    wire [N*7-1:0] partial_results;
    reg [N*7-1:0] registered_results;
    
    // Pipeline stage 1: Calculate partial products
    genvar i;
    generate 
        for(i=0; i<N; i=i+1) begin: gen_conversions
            wire [3:0] bcd_digit;
            wire [7:0] power_10_value;
            
            // Extract BCD digit and determine power of 10
            assign bcd_digit = bcd[i*4+:4];
            assign power_10_value = power_10_lut(i);
            
            // Calculate product using optimized Karatsuba multiplier
            digit_multiplier #(
                .WIDTH(4)
            ) mult_inst (
                .bcd_digit(bcd_digit),
                .power_value(power_10_value[3:0]),
                .partial_result(partial_results[i*7+:7])
            );
        end
    endgenerate
    
    // Pipeline stage 2: Register partial results
    always @(partial_results) begin
        registered_results <= partial_results;
    end
    
    // Pipeline stage 3: Final output
    always @(registered_results) begin
        bin <= registered_results;
    end
    
    // Function to determine power of 10 constant based on position
    function [7:0] power_10_lut;
        input integer power;
        begin
            case(power)
                0: power_10_lut = 8'd1;
                1: power_10_lut = 8'd10;
                2: power_10_lut = 8'd100;
                default: power_10_lut = 8'd0;
            endcase
        end
    endfunction
endmodule

// Intermediate module to handle the multiplication of a BCD digit with a power of 10
module digit_multiplier #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] bcd_digit,
    input [WIDTH-1:0] power_value,
    output [2*WIDTH-1:0] partial_result
);
    // Using Karatsuba multiplier for efficient multiplication
    karatsuba_multiplier #(
        .WIDTH(WIDTH)
    ) karatsuba_inst (
        .a(bcd_digit),
        .b(power_value),
        .product(partial_result)
    );
endmodule

// Karatsuba multiplication module - optimized for smaller area and higher speed
module karatsuba_multiplier #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [2*WIDTH-1:0] product
);
    localparam HALF_WIDTH = WIDTH / 2;
    
    // Split inputs module instance
    wire [HALF_WIDTH-1:0] a_low, b_low;
    wire [HALF_WIDTH-1:0] a_high, b_high;
    reg [HALF_WIDTH-1:0] a_low_reg, b_low_reg;
    reg [HALF_WIDTH-1:0] a_high_reg, b_high_reg;
    
    input_splitter #(
        .WIDTH(WIDTH),
        .HALF_WIDTH(HALF_WIDTH)
    ) splitter_inst (
        .a(a),
        .b(b),
        .a_low(a_low),
        .a_high(a_high),
        .b_low(b_low),
        .b_high(b_high)
    );
    
    // Pipeline stage 1: Input registration and splitting
    always @(*) begin
        a_low_reg <= a_low;
        a_high_reg <= a_high;
        b_low_reg <= b_low;
        b_high_reg <= b_high;
    end
    
    // Pipeline stage 2: Calculate sub-products
    reg [WIDTH-1:0] z0_reg; // a_low * b_low
    reg [WIDTH-1:0] z2_reg; // a_high * b_high
    reg [HALF_WIDTH:0] a_sum_reg; // a_low + a_high
    reg [HALF_WIDTH:0] b_sum_reg; // b_low + b_high
    
    wire [HALF_WIDTH:0] a_sum = a_low_reg + a_high_reg;
    wire [HALF_WIDTH:0] b_sum = b_low_reg + b_high_reg;
    wire [WIDTH-1:0] z0 = a_low_reg * b_low_reg;
    wire [WIDTH-1:0] z2 = a_high_reg * b_high_reg;
    
    always @(*) begin
        z0_reg <= z0;
        z2_reg <= z2;
        a_sum_reg <= a_sum;
        b_sum_reg <= b_sum;
    end
    
    // Pipeline stage 3: Calculate middle term
    reg [WIDTH-1:0] z1_reg;
    wire [WIDTH-1:0] z1 = a_sum_reg * b_sum_reg;
    
    always @(*) begin
        z1_reg <= z1;
    end
    
    // Pipeline stage 4: Apply Karatsuba formula
    reg [WIDTH:0] middle_term_reg;
    wire [WIDTH:0] middle_term = z1_reg - z2_reg - z0_reg;
    
    always @(*) begin
        middle_term_reg <= middle_term;
    end
    
    // Pipeline stage 5: Final product computation through result_combiner
    wire [2*WIDTH-1:0] high_shifted = {z2_reg, {HALF_WIDTH{1'b0}}};
    wire [2*WIDTH-1:0] mid_shifted = {middle_term_reg, {HALF_WIDTH{1'b0}}};
    
    result_combiner #(
        .WIDTH(WIDTH)
    ) combiner_inst (
        .high_shifted(high_shifted),
        .mid_shifted(mid_shifted),
        .z0(z0_reg),
        .product(product)
    );
endmodule

// Input splitter module - splits inputs into high and low parts
module input_splitter #(
    parameter WIDTH = 4,
    parameter HALF_WIDTH = WIDTH / 2
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [HALF_WIDTH-1:0] a_low,
    output [HALF_WIDTH-1:0] a_high,
    output [HALF_WIDTH-1:0] b_low,
    output [HALF_WIDTH-1:0] b_high
);
    // Split inputs into high and low parts
    assign a_low = a[HALF_WIDTH-1:0];
    assign a_high = a[WIDTH-1:HALF_WIDTH];
    assign b_low = b[HALF_WIDTH-1:0];
    assign b_high = b[WIDTH-1:HALF_WIDTH];
endmodule

// Result combiner module - combines partial results to form final product
module result_combiner #(
    parameter WIDTH = 4
)(
    input [2*WIDTH-1:0] high_shifted,
    input [2*WIDTH-1:0] mid_shifted,
    input [WIDTH-1:0] z0,
    output reg [2*WIDTH-1:0] product
);
    // Combine partial results to form final product
    always @(*) begin
        product <= high_shifted + mid_shifted + z0;
    end
endmodule