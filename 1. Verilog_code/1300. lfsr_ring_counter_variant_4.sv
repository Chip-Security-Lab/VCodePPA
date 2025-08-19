//SystemVerilog
module lfsr_ring_counter (
    input wire clk,
    input wire enable,
    output wire [3:0] lfsr_reg
);
    // Internal registers with optimized structure
    reg [3:0] state_reg;
    
    // Optimized state transitions with efficient comparison logic
    always @(posedge clk) begin
        if (!enable) begin
            // Reset state on disable
            state_reg <= 4'b0010;
        end
        else begin
            // Simplified comparison chain using range check
            if (state_reg[3:1] == 3'b000) begin
                // State correction path when zeros detected
                state_reg <= 4'b0010;
            end
            else begin
                // Normal shift operation with feedback
                state_reg <= {state_reg[2:0], state_reg[3]};
            end
        end
    end
    
    // Direct output assignment
    assign lfsr_reg = state_reg;
    
endmodule