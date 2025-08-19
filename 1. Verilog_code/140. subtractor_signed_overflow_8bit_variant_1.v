module subtractor_signed_overflow_8bit (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] diff,
    output overflow
);

    wire [7:0] b_comp = ~b;
    wire [7:0] sum;
    wire [7:0] carry;
    wire [7:0] skip;
    wire [7:0] group_propagate;
    wire [7:0] group_generate;
    
    // Generate and Propagate signals
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_gp
            assign group_generate[i] = a[i] & b_comp[i];
            assign group_propagate[i] = a[i] ^ b_comp[i];
        end
    endgenerate
    
    // Skip carry logic
    assign skip[0] = group_propagate[0];
    assign skip[1] = group_propagate[1] & group_propagate[0];
    assign skip[2] = group_propagate[2] & group_propagate[1] & group_propagate[0];
    assign skip[3] = group_propagate[3] & group_propagate[2] & group_propagate[1] & group_propagate[0];
    assign skip[4] = group_propagate[4] & group_propagate[3] & group_propagate[2] & group_propagate[1] & group_propagate[0];
    assign skip[5] = group_propagate[5] & group_propagate[4] & group_propagate[3] & group_propagate[2] & group_propagate[1] & group_propagate[0];
    assign skip[6] = group_propagate[6] & group_propagate[5] & group_propagate[4] & group_propagate[3] & group_propagate[2] & group_propagate[1] & group_propagate[0];
    assign skip[7] = group_propagate[7] & group_propagate[6] & group_propagate[5] & group_propagate[4] & group_propagate[3] & group_propagate[2] & group_propagate[1] & group_propagate[0];
    
    // Carry computation using skip carry logic
    assign carry[0] = 1'b1;
    assign carry[1] = group_generate[0] | (group_propagate[0] & 1'b1);
    assign carry[2] = group_generate[1] | (group_propagate[1] & carry[1]);
    assign carry[3] = group_generate[2] | (group_propagate[2] & carry[2]);
    assign carry[4] = group_generate[3] | (group_propagate[3] & carry[3]);
    assign carry[5] = group_generate[4] | (group_propagate[4] & carry[4]);
    assign carry[6] = group_generate[5] | (group_propagate[5] & carry[5]);
    assign carry[7] = group_generate[6] | (group_propagate[6] & carry[6]);
    
    // Sum computation
    assign sum = group_propagate ^ carry;
    assign diff = sum;
    
    // Overflow detection
    assign overflow = (a[7] & ~b[7] & ~diff[7]) | (~a[7] & b[7] & diff[7]);

endmodule