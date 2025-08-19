//SystemVerilog
module jk_ff_enable (
    input wire clock_in,
    input wire enable_sig,
    input wire j_input,
    input wire k_input,
    output reg q_output
);
    // Internal signals
    reg enable_reg;
    reg j_reg;
    reg k_reg;
    reg q_internal;
    
    // Combined always block with all posedge clock_in logic
    always @(posedge clock_in) begin
        // Register inputs
        enable_reg <= enable_sig;
        j_reg <= j_input;
        k_reg <= k_input;
        
        // JK flip-flop logic
        if (enable_reg) begin
            case ({j_reg, k_reg})
                2'b00: q_internal <= q_internal;
                2'b01: q_internal <= 1'b0;
                2'b10: q_internal <= 1'b1;
                2'b11: q_internal <= ~q_internal;
            endcase
        end
        
        // Update output
        q_output <= q_internal;
    end
endmodule