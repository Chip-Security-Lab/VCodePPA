//SystemVerilog
//-----------------------------------------------------------------------------
// File: configurable_clock_gate_top.v
//-----------------------------------------------------------------------------
module configurable_clock_gate_top (
    input  wire clk_in,
    input  wire [1:0] mode,
    input  wire ctrl,
    output wire clk_out
);
    // Internal signals
    wire gate_signal;
    
    // Gate control logic submodule
    gate_controller u_gate_controller (
        .mode        (mode),
        .ctrl        (ctrl),
        .gate_signal (gate_signal)
    );
    
    // Clock gating cell submodule
    clock_gate_cell u_clock_gate_cell (
        .clk_in      (clk_in),
        .gate_enable (gate_signal),
        .clk_out     (clk_out)
    );
    
endmodule

//-----------------------------------------------------------------------------
// File: gate_controller.v
//-----------------------------------------------------------------------------
module gate_controller (
    input  wire [1:0] mode,
    input  wire ctrl,
    output wire gate_signal
);
    // Internal mode signals
    wire direct_mode_signal;
    wire inverted_mode_signal;
    wire fixed_mode_signal;
    wire [1:0] selected_output;
    reg gate_signal_reg;
    
    // Handle direct mode (mode 00) logic
    assign direct_mode_signal = ctrl;
    
    // Handle inverted mode (mode 01) logic
    assign inverted_mode_signal = ~ctrl;
    
    // Handle fixed mode (mode 10 and 11) logic
    assign fixed_mode_signal = ~mode[0]; // 1 for mode 10, 0 for mode 11
    
    // Mode selection logic using separate assignments
    assign selected_output[0] = (mode == 2'b00) ? direct_mode_signal : 
                               (mode == 2'b01) ? inverted_mode_signal : 1'b0;
                               
    assign selected_output[1] = (mode[1]) ? fixed_mode_signal : 1'b0;
    
    // Final output multiplexing logic
    assign gate_signal = (mode[1]) ? selected_output[1] : selected_output[0];
    
endmodule

//-----------------------------------------------------------------------------
// File: clock_gate_cell.v
//-----------------------------------------------------------------------------
module clock_gate_cell (
    input  wire clk_in,
    input  wire gate_enable,
    output wire clk_out
);
    // Integrated clock gating cell with latch-based implementation
    // This prevents glitches when gate_enable changes while clk_in is high
    reg latch_enable;
    wire gated_clock;
    
    // Transparent latch that captures gate_enable when clk_in is low
    always @(*) begin
        if (!clk_in)
            latch_enable <= gate_enable;
    end
    
    // Final clock gating logic
    assign clk_out = clk_in & latch_enable;
    
endmodule