//SystemVerilog
module jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output reg q
);
    // Internal signals for retiming
    reg j_reg, k_reg;
    reg next_q;
    
    // Register inputs to reduce input path delay
    always @(posedge clk) begin
        j_reg <= j;
        k_reg <= k;
    end
    
    // Pre-compute next state in separate combinational logic
    always @(*) begin
        case ({j_reg, k_reg})
            2'b00: next_q = q;      // No change
            2'b01: next_q = 1'b0;   // Reset
            2'b10: next_q = 1'b1;   // Set
            2'b11: next_q = ~q;     // Toggle
        endcase
    end
    
    // Output register to maintain functionality
    always @(posedge clk) begin
        q <= next_q;
    end
endmodule