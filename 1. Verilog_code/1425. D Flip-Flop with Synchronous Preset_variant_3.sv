//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module d_ff_sync_preset (
    input  wire clk,
    input  wire preset,
    input  wire d,
    output wire q
);
    // Directly implement the D flip-flop with preset in the top module
    // This eliminates module boundaries and reduces critical path delay
    reg q_reg;
    
    // Fast path for preset condition calculation
    wire preset_active = preset;
    wire d_path = d & ~preset_active;
    wire next_state = d_path | preset_active;
    
    // Sequential logic
    always @(posedge clk) begin
        q_reg <= next_state;
    end
    
    // Output assignment
    assign q = q_reg;
    
endmodule