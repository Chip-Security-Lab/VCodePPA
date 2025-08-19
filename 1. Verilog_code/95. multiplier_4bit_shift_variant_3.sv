//SystemVerilog
module multiplier_4bit_shift (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);

    // Manchester carry chain adder implementation
    wire [7:0] partial_products [3:0];
    wire [7:0] sum;
    wire [7:0] carry;
    
    // Generate partial products
    assign partial_products[0] = b[0] ? {4'b0, a} : 8'b0;
    assign partial_products[1] = b[1] ? {3'b0, a, 1'b0} : 8'b0;
    assign partial_products[2] = b[2] ? {2'b0, a, 2'b0} : 8'b0;
    assign partial_products[3] = b[3] ? {1'b0, a, 3'b0} : 8'b0;

    // Manchester carry chain adder
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_adder
            wire p, g;
            assign p = partial_products[0][i] ^ partial_products[1][i];
            assign g = partial_products[0][i] & partial_products[1][i];
            
            if (i == 0) begin
                assign carry[i] = g;
                assign sum[i] = p;
            end else begin
                assign carry[i] = g | (p & carry[i-1]);
                assign sum[i] = p ^ carry[i-1];
            end
        end
    endgenerate

    // Final addition stage
    wire [7:0] temp_sum;
    assign temp_sum = sum ^ partial_products[2];
    assign product = temp_sum ^ partial_products[3];

endmodule