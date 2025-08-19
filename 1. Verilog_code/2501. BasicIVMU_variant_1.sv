module BasicIVMU (
    input wire clk, rst_n,
    input wire [7:0] int_req,
    output reg [31:0] vector_addr,
    output reg int_valid
);
    // No longer need vec_table

    // Register the input request signal (Backward retiming applied)
    reg [7:0] registered_int_req;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            registered_int_req <= 8'h0;
        end else begin
            registered_int_req <= int_req;
        end
    end

    // Combinatorial logic: Priority Encoding and Index Calculation
    // This logic now operates on the registered input
    wire [2:0] calculated_index;
    wire calculated_valid;

    // Combinatorial logic to find the highest priority request and its index
    assign calculated_valid = |registered_int_req;

    // Explicit priority encoder (equivalent to the original loop's behavior)
    assign calculated_index = registered_int_req[0] ? 3'd0 :
                              registered_int_req[1] ? 3'd1 :
                              registered_int_req[2] ? 3'd2 :
                              registered_int_req[3] ? 3'd3 :
                              registered_int_req[4] ? 3'd4 :
                              registered_int_req[5] ? 3'd5 :
                              registered_int_req[6] ? 3'd6 :
                              registered_int_req[7] ? 3'd7 : 3'd0; // Default value when no request (ignored if calculated_valid is 0)

    // Carry-Lookahead Adder (CLA) implementation for vector_addr calculation
    // Replaces the vec_table lookup with a runtime calculation: 32'h1000_0000 + (calculated_index << 2)

    wire [31:0] add_a_const = 32'h1000_0000;
    wire [31:0] add_b_shifted = {29'b0, calculated_index, 2'b00};

    wire [31:0] p, g; // Propagate and Generate signals for each bit
    wire [7:0] block_P, block_G; // Block Propagate and Generate signals (4-bit blocks)
    wire [8:0] block_C; // Carry into each block (C0 to C8)
    wire [31:0] bit_carries; // Carry into each bit within its block logic
    wire [31:0] calculated_vector_addr; // Result of the CLA

    // Calculate bitwise Propagate and Generate
    assign p = add_a_const ^ add_b_shifted;
    assign g = add_a_const & add_b_shifted;

    // Calculate Block Propagate and Generate (4-bit blocks)
    generate
        genvar j;
        for (j = 0; j < 8; j = j + 1) begin : block_pg
            assign block_P[j] = p[4*j+3] & p[4*j+2] & p[4*j+1] & p[4*j];
            assign block_G[j] = g[4*j+3] | (p[4*j+3] & g[4*j+2]) | (p[4*j+3] & p[4*j+2] & g[4*j+1]) | (p[4*j+3] & p[4*j+2] & p[4*j+1] & g[4*j]);
        end
    endgenerate

    // Calculate Block Carries using Lookahead
    assign block_C[0] = 1'b0; // Overall Cin is 0
    assign block_C[1] = block_G[0] | (block_P[0] & block_C[0]);
    assign block_C[2] = block_G[1] | (block_P[1] & block_C[1]);
    assign block_C[3] = block_G[2] | (block_P[2] & block_C[2]);
    assign block_C[4] = block_G[3] | (block_P[3] & block_C[3]);
    assign block_C[5] = block_G[4] | (block_P[4] & block_C[4]);
    assign block_C[6] = block_G[5] | (block_P[5] & block_C[5]);
    assign block_C[7] = block_G[6] | (block_P[6] & block_C[6]);
    assign block_C[8] = block_G[7] | (block_P[7] & block_C[7]); // Overall Cout (not used)

    // Calculate internal carries within each block
    generate
        genvar k;
        for (k = 0; k < 8; k = k + 1) begin : internal_carries
            assign bit_carries[4*k]   = block_C[k]; // Carry into the first bit of the block
            assign bit_carries[4*k+1] = g[4*k]   | (p[4*k]   & bit_carries[4*k]);
            assign bit_carries[4*k+2] = g[4*k+1] | (p[4*k+1] & bit_carries[4*k+1]);
            assign bit_carries[4*k+3] = g[4*k+2] | (p[4*k+2] & bit_carries[4*k+2]);
        end
    endgenerate

    // Calculate Sum bits using Propagate and internal carries
    generate
        genvar bit_idx;
        for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1) begin : sum_bits
            assign calculated_vector_addr[bit_idx] = p[bit_idx] ^ bit_carries[bit_idx];
        end
    endgenerate


    // Registered outputs (Stage 2 logic and registers)
    // The logic for the output registers now uses the combinatorially calculated values
    // based on the registered input (registered_int_req) from the previous cycle.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_addr <= 32'h0;
            int_valid <= 1'b0;
        end else begin
            // int_valid is high one cycle after registered_int_req was high (via calculated_valid)
            int_valid <= calculated_valid;

            // Only update vector_addr if the calculated request was valid
            if (calculated_valid) begin
                 // Use the address calculated by the CLA
                 vector_addr <= calculated_vector_addr;
            end
            // If calculated_valid is 0, vector_addr retains its previous value,
            // preserving the original sticky behavior.
        end
    end

    // No initial block needed as vec_table is removed

endmodule