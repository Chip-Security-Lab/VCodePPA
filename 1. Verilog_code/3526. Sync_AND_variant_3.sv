//SystemVerilog
module Sync_AND (
    input wire clk,
    input wire [7:0] signal_a, signal_b,
    output reg [7:0] reg_out
);
    // Pipeline stage 1: Input registers to capture input signals
    reg [7:0] signal_a_reg, signal_b_reg;
    
    // Pipeline stage 2: Computation result register
    reg [7:0] and_result_reg;
    
    // Split the datapath into pipeline stages for improved timing
    always @(posedge clk) begin
        // Stage 1: Register inputs
        signal_a_reg <= signal_a;
        signal_b_reg <= signal_b;
        
        // Stage 2: Compute and register intermediate result
        and_result_reg <= signal_a_reg & signal_b_reg;
        
        // Stage 3: Register final output
        reg_out <= and_result_reg;
    end
endmodule