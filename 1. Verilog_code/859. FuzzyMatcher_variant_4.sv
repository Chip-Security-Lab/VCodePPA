//SystemVerilog
module FuzzyMatcher #(parameter WIDTH=8, THRESHOLD=2) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg match
);
    // XOR to find different bits
    wire [WIDTH-1:0] xor_result = data ^ pattern;
    
    // Optimized bit counting using carry-lookahead adder approach
    reg [7:0] ones_count;
    
    // Carry signals for efficient bit counting
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum;
    
    // Initialize carry-in to 0
    assign carry[0] = 1'b0;
    
    // Generate propagate and generate signals
    wire [WIDTH-1:0] p, g;
    
    // Calculate p (propagate) and g (generate) for each bit
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: pg_gen
            assign p[j] = xor_result[j];
            assign g[j] = 1'b0; // For counting, generate is 0
        end
    endgenerate
    
    // Carry-lookahead logic for 8-bit width (4-bit CLA blocks)
    generate
        if (WIDTH <= 4) begin: small_cla
            // For small widths, direct carry calculation
            for (j = 0; j < WIDTH; j = j + 1) begin: carry_gen
                assign carry[j+1] = p[j] & carry[j];
            end
        end
        else begin: cla_blocks
            // First CLA block (bits 0-3)
            wire [3:0] c1;
            assign c1[0] = carry[0];
            assign c1[1] = p[0] & c1[0];
            assign c1[2] = p[1] & c1[1];
            assign c1[3] = p[2] & c1[2];
            assign carry[1] = c1[1];
            assign carry[2] = c1[2];
            assign carry[3] = c1[3];
            assign carry[4] = p[3] & c1[3];
            
            // Second CLA block (bits 4-7)
            wire [3:0] c2;
            assign c2[0] = carry[4];
            assign c2[1] = p[4] & c2[0];
            assign c2[2] = p[5] & c2[1];
            assign c2[3] = p[6] & c2[2];
            assign carry[5] = c2[1];
            assign carry[6] = c2[2];
            assign carry[7] = c2[3];
            assign carry[8] = p[7] & c2[3];
        end
    endgenerate
    
    // Sum calculation
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: sum_gen
            assign sum[j] = p[j] ^ carry[j];
        end
    endgenerate
    
    // Calculate total ones using the CLA adder outputs
    always @* begin
        ones_count = 0;
        case (WIDTH)
            1: ones_count = sum[0];
            2: ones_count = sum[0] + sum[1] + carry[2];
            3: ones_count = sum[0] + sum[1] + sum[2] + carry[3];
            4: ones_count = sum[0] + sum[1] + sum[2] + sum[3] + carry[4];
            default: begin
                // Use optimized summation with carry information
                ones_count = sum[0] + sum[1] + sum[2] + sum[3] + 
                             sum[4] + sum[5] + sum[6] + sum[7] + carry[WIDTH];
            end
        endcase
        
        // Final comparison with threshold
        match = (ones_count <= THRESHOLD);
    end
endmodule