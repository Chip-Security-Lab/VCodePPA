//SystemVerilog
module jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output wire q
);
    reg q_reg;
    reg j_reg, k_reg;
    reg next_q;
    
    // Register inputs to improve setup time
    always @(posedge clk) begin
        j_reg <= j;
        k_reg <= k;
    end
    
    // Combinational logic for next state
    always @(*) begin
        case ({j_reg, k_reg})
            2'b00: next_q = q_reg;   // No change
            2'b01: next_q = 1'b0;    // Reset
            2'b10: next_q = 1'b1;    // Set
            2'b11: next_q = ~q_reg;  // Toggle
        endcase
    end
    
    // Register the next state
    always @(posedge clk) begin
        q_reg <= next_q;
    end
    
    // Connect register to output
    assign q = q_reg;
    
endmodule