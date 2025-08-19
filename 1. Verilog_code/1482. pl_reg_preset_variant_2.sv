//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: pl_reg_preset
// Description: Pipelined preset register with load and shift functionality
///////////////////////////////////////////////////////////////////////////////
module pl_reg_preset #(
    parameter W = 8,              // Register width
    parameter PRESET = 8'hFF      // Default preset value
) (
    input  wire           clk,      // System clock
    input  wire           load,     // Load control signal
    input  wire           shift_in, // Serial input for shift operation
    output wire [W-1:0]   q         // Registered output
);

    // Direct combinational signals
    wire load_direct;
    wire shift_in_direct;
    
    // Internal pipeline signals for final stage
    reg [W-1:0] q_reg;
    
    // Forward-retimed approach - register direct inputs
    reg load_retimed;
    reg shift_in_retimed;
    reg [W-1:0] q_next_retimed;
    
    // Assign direct signals to drive combinational logic
    assign load_direct = load;
    assign shift_in_direct = shift_in;
    
    // Compute q_next combinationally based on direct inputs
    // (moved before registers to enable forward retiming)
    always @(posedge clk) begin
        if (load_direct)
            q_next_retimed <= PRESET;
        else
            q_next_retimed <= {q_reg[W-2:0], shift_in_direct};
            
        // Register the inputs after their use in combinational logic
        load_retimed <= load_direct;
        shift_in_retimed <= shift_in_direct;
    end
    
    // Final output register
    always @(posedge clk) begin
        q_reg <= q_next_retimed;
    end
    
    // Connect output
    assign q = q_reg;

endmodule