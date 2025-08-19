//SystemVerilog
module async_sel_decoder (
    input [1:0] sel,
    input enable,
    output reg [3:0] out_bus
);
    // Dadda multiplier implementation for 4-bit operands
    wire [3:0] a, b;
    wire [7:0] product;
    
    // Convert sel to 4-bit operands
    assign a = {2'b00, sel};
    assign b = 4'b0001;
    
    // Dadda multiplier implementation
    dadda_mult_4bit dadda_inst (
        .a(a),
        .b(b),
        .product(product)
    );
    
    // Output logic
    always @(*) begin
        if (!enable) begin
            out_bus = 4'b0000;
        end else begin
            out_bus = product[3:0];
        end
    end
endmodule

// Dadda multiplier for 4-bit operands
module dadda_mult_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // Partial products
    wire [3:0] pp0, pp1, pp2, pp3;
    
    // Generate partial products
    assign pp0 = a & {4{b[0]}};
    assign pp1 = a & {4{b[1]}};
    assign pp2 = a & {4{b[2]}};
    assign pp3 = a & {4{b[3]}};
    
    // Dadda tree reduction
    // First stage: 4:2 compressors
    wire [4:0] sum1, carry1;
    wire [4:0] sum2, carry2;
    
    // First compressor
    assign sum1[0] = pp0[0];
    assign carry1[0] = 1'b0;
    
    assign sum1[1] = pp0[1] ^ pp1[0];
    assign carry1[1] = pp0[1] & pp1[0];
    
    assign sum1[2] = pp0[2] ^ pp1[1] ^ pp2[0];
    assign carry1[2] = (pp0[2] & pp1[1]) | ((pp0[2] ^ pp1[1]) & pp2[0]);
    
    assign sum1[3] = pp0[3] ^ pp1[2] ^ pp2[1] ^ pp3[0];
    assign carry1[3] = (pp0[3] & pp1[2]) | ((pp0[3] ^ pp1[2]) & pp2[1]) | ((pp0[3] ^ pp1[2] ^ pp2[1]) & pp3[0]);
    
    assign sum1[4] = pp1[3] ^ pp2[2] ^ pp3[1];
    assign carry1[4] = (pp1[3] & pp2[2]) | ((pp1[3] ^ pp2[2]) & pp3[1]);
    
    // Second compressor
    assign sum2[0] = sum1[0];
    assign carry2[0] = 1'b0;
    
    assign sum2[1] = sum1[1] ^ carry1[0];
    assign carry2[1] = sum1[1] & carry1[0];
    
    assign sum2[2] = sum1[2] ^ carry1[1] ^ pp2[0];
    assign carry2[2] = (sum1[2] & carry1[1]) | ((sum1[2] ^ carry1[1]) & pp2[0]);
    
    assign sum2[3] = sum1[3] ^ carry1[2] ^ pp2[1] ^ pp3[0];
    assign carry2[3] = (sum1[3] & carry1[2]) | ((sum1[3] ^ carry1[2]) & pp2[1]) | ((sum1[3] ^ carry1[2] ^ pp2[1]) & pp3[0]);
    
    assign sum2[4] = sum1[4] ^ carry1[3] ^ pp2[2] ^ pp3[1];
    assign carry2[4] = (sum1[4] & carry1[3]) | ((sum1[4] ^ carry1[3]) & pp2[2]) | ((sum1[4] ^ carry1[3] ^ pp2[2]) & pp3[1]);
    
    // Final addition
    wire [7:0] temp_sum, temp_carry;
    
    assign temp_sum = {sum2[4:0], 3'b000};
    assign temp_carry = {carry2[3:0], 4'b0000};
    
    // Final product
    assign product = temp_sum + temp_carry;
endmodule