//SystemVerilog
module CombinationalArbiter #(parameter N=4) (
    input [N-1:0] req,
    output [N-1:0] grant
);
    // Intermediate signals for improved readability and synthesis
    wire [N-1:0] req_inv;
    wire [N-1:0] mask;
    wire [N:0] carry;
    
    // Invert request signals
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_inv
            assign req_inv[i] = ~req[i];
        end
    endgenerate
    
    // Initialize carry chain
    assign carry[0] = 1'b1;
    
    // Two-level carry generation
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_carry
            wire carry_prop;
            wire carry_gen;
            
            // Carry propagate and generate terms
            assign carry_prop = req[i] ^ carry[i];
            assign carry_gen = req_inv[i] & carry[i];
            
            // Next carry calculation
            assign carry[i+1] = carry_prop | carry_gen;
            
            // Mask generation
            assign mask[i] = req_inv[i] ^ carry[i];
        end
    endgenerate
    
    // Final grant calculation with explicit masking
    assign grant = req & ~mask;
endmodule