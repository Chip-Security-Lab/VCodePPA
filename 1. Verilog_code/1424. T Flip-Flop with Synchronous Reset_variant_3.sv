//SystemVerilog
// Top level module - IEEE 1364-2005 Verilog standard
module t_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire toggle,
    output wire q_out
);
    // Internal signals
    reg toggle_reg;
    wire internal_toggle;
    
    // Register the toggle input
    always @(posedge clock) begin
        if (reset)
            toggle_reg <= 1'b0;
        else
            toggle_reg <= toggle;
    end
    
    // Generate internal toggle signal - moved logic before the register
    assign internal_toggle = toggle_reg ? ~q_out : q_out;
    
    // State register with synchronous reset - moved closer to outputs
    reg current_state;
    always @(posedge clock) begin
        if (reset)
            current_state <= 1'b0;
        else
            current_state <= internal_toggle;
    end
    
    // Output assignment
    assign q_out = current_state;
    
endmodule