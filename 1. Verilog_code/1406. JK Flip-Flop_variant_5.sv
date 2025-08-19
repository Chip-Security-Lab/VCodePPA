//SystemVerilog
module jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output wire q
);
    // Registered inputs
    reg j_reg, k_reg;
    reg q_int;
    
    // Combined always block for both input registration and JK logic
    always @(posedge clk) begin
        // First register the inputs
        j_reg <= j;
        k_reg <= k;
        
        // Then process JK logic with current registered values
        case ({j_reg, k_reg})
            2'b00: q_int <= q_int;   // No change
            2'b01: q_int <= 1'b0;    // Reset
            2'b10: q_int <= 1'b1;    // Set
            2'b11: q_int <= ~q_int;  // Toggle
        endcase
    end
    
    // Output assignment
    assign q = q_int;
    
endmodule