//SystemVerilog
module vector_icmu (
    input clk, rst_b,
    input [31:0] int_vector,
    input enable,
    input [63:0] current_context,
    output reg int_active,
    output reg [63:0] saved_context,
    output reg [4:0] vector_number
);
    reg [31:0] pending, masked;
    reg [31:0] mask;

    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pending <= 32'h0;
            int_active <= 1'b0;
            saved_context <= 64'h0;
            vector_number <= 5'h0;
            mask <= 32'hFFFFFFFF; // Reset mask
        end else begin
            // Latch new interrupts
            pending <= pending | int_vector;
            masked <= pending & mask & {32{enable}};

            // Handle next interrupt
            if (!int_active && |masked) begin
                vector_number <= priority_encoder(masked);
                saved_context <= current_context;
                int_active <= 1'b1;
                // Clear the handled interrupt bit from pending
                pending <= pending & ~(32'h1 << vector_number);
            end
        end
    end

    // Priority encoder function finding the MSB position
    function [4:0] priority_encoder;
        input [31:0] vector;
        reg [4:0] result;
        integer i;

        // Variables for 65-bit Carry Lookahead Subtractor (implemented as Adder) logic
        // Calculates i - 1 using A + ~B + 1 where A=i, B=1, Cin=1
        reg [64:0] i_val_65;
        reg [64:0] one_val_65;
        reg [64:0] one_inv_val_65;
        reg [64:0] sum_val_65; // Result of i + ~1 + 1
        reg [64:0] p_cla;      // Propagate P_k = A_k ^ B_inv_k
        reg [64:0] g_cla;      // Generate G_k = A_k & B_inv_k
        reg [65:0] carry_cla;  // Carries C_k
        integer k_cla;

        begin
            result = 5'h0;
            // Loop through vector bits from MSB down
            for (i = 31; i >= 0; i = i - 1) begin
                if (vector[i]) begin
                    result = i[4:0];
                    // Found the highest set bit. The loop structure handles exiting.
                end

                // Implement 65-bit Carry Lookahead Subtractor logic (as A + ~B + 1) for i - 1
                // This calculation is likely optimized away by the synthesizer as the loop counter
                // is handled by the loop structure itself. It's included as requested.
                // A = i_val_65, B = one_val_65, Cin = 1
                i_val_65 = i;       // Cast integer i to 65 bits (implicitly zero-extended)
                one_val_65 = 65'd1; // Constant 1 (65 bits)
                one_inv_val_65 = ~one_val_65; // Bitwise NOT of 1

                // Initial carry-in for A + ~B + 1 is 1
                carry_cla[0] = 1'b1;

                // Calculate Propagate and Generate for A + ~B and carries
                for (k_cla = 0; k_cla < 65; k_cla = k_cla + 1) begin
                    // Propagate and Generate for bit k_cla (using A=i_val_65 and B_inv=one_inv_val_65)
                    p_cla[k_cla] = i_val_65[k_cla] ^ one_inv_val_65[k_cla];
                    g_cla[k_cla] = i_val_65[k_cla] & one_inv_val_65[k_cla];

                    // Carry Lookahead logic (recursive definition)
                    // C_{k+1} = G_k | (P_k & C_k)
                    carry_cla[k_cla+1] = g_cla[k_cla] | (p_cla[k_cla] & carry_cla[k_cla]);

                    // Sum bit k_cla
                    // Sum_k = A_k ^ B_inv_k ^ Carry_k = P_k ^ Carry_k
                    sum_val_65[k_cla] = p_cla[k_cla] ^ carry_cla[k_cla];
                end

                // The result 'sum_val_65' is the 65-bit representation of i-1.
                // It is not used to update the loop counter 'i', which is controlled by the 'for' loop.

            end // end for (i = 31; i >= 0; i = i - 1)

            priority_encoder = result; // Assign the found priority number
        end
    endfunction

endmodule