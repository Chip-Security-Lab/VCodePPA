//SystemVerilog
//-----------------------------------------------------------------------------
// File: jk_ff_preset_top.v
// Module: jk_ff_preset_top
// Description: Top level module for JK flip-flop with preset
// Standard: IEEE 1364-2005 Verilog
//-----------------------------------------------------------------------------
module jk_ff_preset_top (
    input  wire clk,
    input  wire preset_n,
    input  wire j,
    input  wire k,
    output wire q
);
    // Internal signals
    wire [1:0] jk_combined;
    wire next_state;
    wire current_q;
    
    // Combinational logic module
    jk_ff_comb_logic u_comb_logic (
        .j(j),
        .k(k),
        .current_q(current_q),
        .jk_combined(jk_combined),
        .next_state(next_state)
    );
    
    // Sequential logic module
    jk_ff_seq_logic u_seq_logic (
        .clk(clk),
        .preset_n(preset_n),
        .next_q(next_state),
        .q(current_q)
    );
    
    // Output assignment
    assign q = current_q;
    
endmodule

//-----------------------------------------------------------------------------
// Module: jk_ff_comb_logic
// Description: Combined module for all combinational logic of JK flip-flop
//-----------------------------------------------------------------------------
module jk_ff_comb_logic (
    input  wire j,
    input  wire k,
    input  wire current_q,
    output wire [1:0] jk_combined,
    output wire next_state
);
    // Combine J and K into a single control bus
    assign jk_combined = {j, k};
    
    // Next state determination based on JK inputs and current state
    reg next_state_reg;
    
    always @(*) begin
        case (jk_combined)
            2'b00: next_state_reg = current_q;    // Hold state
            2'b01: next_state_reg = 1'b0;         // Reset
            2'b10: next_state_reg = 1'b1;         // Set
            2'b11: next_state_reg = ~current_q;   // Toggle
            default: next_state_reg = current_q;  // Default case
        endcase
    end
    
    assign next_state = next_state_reg;
    
endmodule

//-----------------------------------------------------------------------------
// Module: jk_ff_seq_logic
// Description: Sequential logic module containing all registers
//-----------------------------------------------------------------------------
module jk_ff_seq_logic (
    input  wire clk,
    input  wire preset_n,
    input  wire next_q,
    output reg  q
);
    // State register with asynchronous preset
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n)
            q <= 1'b1;  // Preset active (active low)
        else
            q <= next_q;
    end
    
    // Output assignment to internal signal
    
endmodule