//SystemVerilog
module lfsr_counter (
    input wire clk, rst,
    output reg [7:0] lfsr
);
    // Registered tap values to reduce input-to-register delay
    reg tap7_reg, tap5_reg, tap4_reg, tap3_reg;
    
    // Feedback computation
    wire xor_stage1 = tap7_reg ^ tap5_reg;
    wire xor_stage2 = tap4_reg ^ tap3_reg;
    wire feedback = xor_stage1 ^ xor_stage2;
    
    // Calculate next state
    wire [7:0] next_lfsr = {lfsr[6:0], feedback};
    
    always @(posedge clk) begin
        if (rst) begin
            // Reset state
            lfsr <= 8'h01;  // Non-zero seed value
            tap7_reg <= 1'b0;
            tap5_reg <= 1'b0;
            tap4_reg <= 1'b0;
            tap3_reg <= 1'b0;
        end
        else begin
            // Update LFSR state
            lfsr <= next_lfsr;
            
            // Register tap values from current LFSR state
            // This moves registers forward through the combinational logic
            tap7_reg <= lfsr[7];
            tap5_reg <= lfsr[5];
            tap4_reg <= lfsr[4];
            tap3_reg <= lfsr[3];
        end
    end
endmodule