//SystemVerilog
// Top module - D Flip Flop with Enable
module d_ff_enable (
    input wire clock,
    input wire enable,
    input wire data_in,
    output wire data_out
);
    // Internal signals
    wire mux_out;
    
    // Instantiate submodules
    mux_2to1 input_selector (
        .sel(enable),
        .in0(data_out),
        .in1(data_in),
        .out(mux_out)
    );
    
    dff_core flip_flop (
        .clock(clock),
        .d(mux_out),
        .q(data_out)
    );
    
endmodule

// 2-to-1 Multiplexer submodule
module mux_2to1 (
    input wire sel,
    input wire in0,
    input wire in1,
    output wire out
);
    // Combinational logic for multiplexer
    assign out = sel ? in1 : in0;
endmodule

// Basic D Flip-Flop core
module dff_core (
    input wire clock,
    input wire d,
    output reg q
);
    // Simple positive-edge triggered D flip-flop
    always @(posedge clock) begin
        q <= d;
    end
endmodule