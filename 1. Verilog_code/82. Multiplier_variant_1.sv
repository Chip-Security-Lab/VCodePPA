//SystemVerilog
module Multiplier2#(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [2*WIDTH-1:0] product
);

    // Optimized partial products generation
    wire [WIDTH-1:0] pp [WIDTH-1:0];
    genvar i, j;
    generate
        for(i=0; i<WIDTH; i=i+1) begin: PP_GEN
            for(j=0; j<WIDTH; j=j+1) begin: PP_ROW
                assign pp[i][j] = x[j] & y[i];
            end
        end
    endgenerate

    // Optimized Dadda tree reduction
    wire [2*WIDTH-1:0] sum, carry;
    DaddaTree #(.WIDTH(WIDTH)) dadda_tree(
        .pp(pp),
        .sum(sum),
        .carry(carry)
    );

    // Optimized final addition using carry-save
    assign product = sum + {carry[2*WIDTH-2:0], 1'b0};

endmodule

module DaddaTree #(parameter WIDTH=4)(
    input [WIDTH-1:0] pp [WIDTH-1:0],
    output [2*WIDTH-1:0] sum,
    output [2*WIDTH-1:0] carry
);

    // Optimized stage 1 with reduced logic depth
    wire [2*WIDTH-1:0] stage1_sum, stage1_carry;
    generate
        for(genvar i=0; i<2*WIDTH-1; i=i+1) begin: STAGE1
            if(i < WIDTH) begin
                assign stage1_sum[i] = pp[i][0];
                assign stage1_carry[i] = 1'b0;
            end else begin
                // Optimized full adder implementation
                wire ab = pp[i-WIDTH][WIDTH-1] & pp[i-WIDTH+1][WIDTH-2];
                wire ac = pp[i-WIDTH][WIDTH-1] & 1'b0;
                wire bc = pp[i-WIDTH+1][WIDTH-2] & 1'b0;
                
                assign stage1_sum[i] = pp[i-WIDTH][WIDTH-1] ^ pp[i-WIDTH+1][WIDTH-2] ^ 1'b0;
                assign stage1_carry[i+1] = ab | ac | bc;
            end
        end
    endgenerate

    // Optimized final reduction
    assign sum = stage1_sum;
    assign carry = stage1_carry;

endmodule