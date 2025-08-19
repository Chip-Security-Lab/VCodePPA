//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: d_ff_sync_preset_top.v
// Description: Top-level module for D flip-flop with synchronous preset
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module d_ff_sync_preset (
    input wire clk,
    input wire preset,
    input wire d,
    output wire q
);
    // Internal signals
    reg d_reg, preset_reg;
    wire next_state;
    
    // Input registers for front-end retiming
    always @(posedge clk) begin
        d_reg <= d;
        preset_reg <= preset;
    end
    
    // State logic submodule
    state_logic state_logic_inst (
        .preset(preset_reg),
        .d(d_reg),
        .next_state(next_state)
    );
    
    // State register submodule
    state_register state_register_inst (
        .clk(clk),
        .next_state(next_state),
        .q(q)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: state_logic.v
// Description: Combinational logic for D flip-flop state computation
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module state_logic (
    input wire preset,
    input wire d,
    output wire next_state
);
    // Determine next state based on preset and d input
    assign next_state = preset ? 1'b1 : d;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: state_register.v
// Description: Sequential register for D flip-flop
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module state_register (
    input wire clk,
    input wire next_state,
    output reg q
);
    // Register with positive edge trigger
    always @(posedge clk) begin
        q <= next_state;
    end
    
endmodule