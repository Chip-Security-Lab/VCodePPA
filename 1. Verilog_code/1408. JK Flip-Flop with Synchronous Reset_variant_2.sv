//SystemVerilog
module jk_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire j_in,
    input wire k_in,
    output reg q_out
);
    // Internal signals for retimed implementation
    reg j_reg, k_reg;
    wire next_state;
    
    // Register input signals to reduce input path delay
    always @(posedge clock) begin
        if (reset) begin
            j_reg <= 1'b0;
            k_reg <= 1'b0;
        end else begin
            j_reg <= j_in;
            k_reg <= k_in;
        end
    end
    
    // Calculate next state using registered inputs
    assign next_state = (j_reg & ~q_out) | (~k_reg & q_out);
    
    // Output register
    always @(posedge clock) begin
        if (reset)
            q_out <= 1'b0;
        else
            q_out <= next_state;
    end
endmodule