//SystemVerilog
// Top level module
module karatsuba_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b, 
    output wire [15:0] p
);

    // Split inputs
    wire [3:0] a_high, a_low;
    wire [3:0] b_high, b_low;
    
    input_splitter splitter (
        .a(a),
        .b(b),
        .a_high(a_high),
        .a_low(a_low),
        .b_high(b_high),
        .b_low(b_low)
    );

    // Partial products
    wire [7:0] p0, p1, p2;
    
    partial_product_calc pp_calc (
        .a_high(a_high),
        .a_low(a_low),
        .b_high(b_high),
        .b_low(b_low),
        .p0(p0),
        .p1(p1),
        .p2(p2)
    );

    // Final product calculation
    final_product_calc final_calc (
        .p0(p0),
        .p1(p1),
        .p2(p2),
        .p(p)
    );

endmodule

// Input splitter module
module input_splitter (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [3:0] a_high,
    output wire [3:0] a_low,
    output wire [3:0] b_high,
    output wire [3:0] b_low
);
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
endmodule

// Partial product calculation module
module partial_product_calc (
    input wire [3:0] a_high,
    input wire [3:0] a_low,
    input wire [3:0] b_high,
    input wire [3:0] b_low,
    output wire [7:0] p0,
    output wire [7:0] p1,
    output wire [7:0] p2
);
    assign p0 = a_low * b_low;
    assign p1 = a_high * b_high;
    assign p2 = (a_high + a_low) * (b_high + b_low);
endmodule

// Final product calculation module
module final_product_calc (
    input wire [7:0] p0,
    input wire [7:0] p1,
    input wire [7:0] p2,
    output wire [15:0] p
);
    wire [15:0] p1_shifted;
    wire [11:0] p2_shifted;
    wire [7:0] p0_shifted;

    assign p1_shifted = {p1, 8'b0};
    assign p2_shifted = {4'b0, p2 - p1 - p0, 4'b0};
    assign p0_shifted = p0;
    assign p = p1_shifted + p2_shifted + p0_shifted;
endmodule