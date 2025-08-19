//SystemVerilog
module neg_edge_sync_reset_reg(
    input clk, rst,
    input [15:0] d_in,
    input load,
    output reg [15:0] q_out
);
    // Pipeline registers for input
    reg [15:0] d_in_reg;
    reg load_reg;
    
    // Consolidate flip-flops to reduce power and area
    always @(negedge clk) begin
        if (rst) begin
            // Reset all registers in a single block
            d_in_reg <= 16'b0;
            load_reg <= 1'b0;
            q_out <= 16'b0;
        end else begin
            // Register inputs
            d_in_reg <= d_in;
            load_reg <= load;
            
            // Update output conditionally in the same clock cycle
            if (load_reg)
                q_out <= d_in_reg;
        end
    end
    
endmodule