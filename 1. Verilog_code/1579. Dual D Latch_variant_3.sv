//SystemVerilog
module dual_d_latch (
    input wire [1:0] d_in,
    input wire latch_enable,
    output reg [1:0] q_out
);
    // Simplified implementation for 2-bit multiplication
    wire [1:0] result;
    
    // Direct calculation of 2-bit multiplication result
    // For 2-bit multiplication: result = d_in * d_in
    // This is equivalent to: result[0] = d_in[0] & d_in[0]
    //                        result[1] = (d_in[0] & d_in[1]) | (d_in[1] & d_in[0])
    
    // Simplified using Boolean algebra:
    // d_in[0] & d_in[0] = d_in[0] (idempotent law)
    // (d_in[0] & d_in[1]) | (d_in[1] & d_in[0]) = d_in[0] & d_in[1] (commutative law)
    
    assign result[0] = d_in[0];
    assign result[1] = d_in[0] & d_in[1];
    
    always @* begin
        if (latch_enable)
            q_out = result;
    end
endmodule