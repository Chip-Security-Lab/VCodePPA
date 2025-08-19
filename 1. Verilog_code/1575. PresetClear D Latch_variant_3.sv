//SystemVerilog
module baugh_wooley_multiplier_8bit (
    input wire signed [7:0] a,
    input wire signed [7:0] b,
    output wire signed [15:0] product
);

    // Partial products
    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    wire [7:0] pp0_ext, pp1_ext, pp2_ext, pp3_ext, pp4_ext, pp5_ext, pp6_ext, pp7_ext;
    
    // Generate partial products
    assign pp0 = {8{a[0]}} & b;
    assign pp1 = {8{a[1]}} & b;
    assign pp2 = {8{a[2]}} & b;
    assign pp3 = {8{a[3]}} & b;
    assign pp4 = {8{a[4]}} & b;
    assign pp5 = {8{a[5]}} & b;
    assign pp6 = {8{a[6]}} & b;
    assign pp7 = {8{a[7]}} & b;
    
    // Sign extension for partial products
    assign pp0_ext = {8'b0, pp0};
    assign pp1_ext = {7'b0, pp1, 1'b0};
    assign pp2_ext = {6'b0, pp2, 2'b0};
    assign pp3_ext = {5'b0, pp3, 3'b0};
    assign pp4_ext = {4'b0, pp4, 4'b0};
    assign pp5_ext = {3'b0, pp5, 5'b0};
    assign pp6_ext = {2'b0, pp6, 6'b0};
    assign pp7_ext = {1'b0, pp7, 7'b0};
    
    // Final addition
    assign product = pp0_ext + pp1_ext + pp2_ext + pp3_ext + pp4_ext + pp5_ext + pp6_ext + pp7_ext;

endmodule