//SystemVerilog
module fsm_div #(parameter EVEN=4, ODD=5) (
    input clk, mode, rst_n,
    output reg clk_out
);
    // Using one-hot encoding for better timing and lower power
    reg [ODD-1:0] state_oh;
    // Pre-compute parameters for division control
    wire [2:0] max_count = mode ? ODD-1 : EVEN-1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            state_oh <= {{(ODD-1){1'b0}}, 1'b1}; // One-hot reset state
            clk_out <= 1'b0;
        end else begin
            // Shift state register or wrap around
            if ((mode && state_oh[ODD-1]) || (!mode && state_oh[EVEN-1]))
                state_oh <= {{(ODD-1){1'b0}}, 1'b1};
            else
                state_oh <= {state_oh[ODD-2:0], state_oh[ODD-1]};
                
            // Direct lookup for clock output based on one-hot state
            // This eliminates comparison operations
            if (mode)
                clk_out <= |state_oh[ODD-1:ODD/2];
            else
                clk_out <= |state_oh[EVEN-1:EVEN/2];
        end
    end
endmodule