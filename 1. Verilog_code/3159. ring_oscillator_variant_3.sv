//SystemVerilog
// Top-level module
module ring_oscillator(
    input  wire enable,
    output wire clk_out
);

    // Internal signals
    wire [4:0] osc_stage;
    
    // Instantiate submodules
    enable_control enable_ctrl(
        .enable(enable),
        .feedback(osc_stage[4]),
        .stage_out(osc_stage[0])
    );
    
    inversion_stage inv_stage1(
        .in(osc_stage[0]),
        .out(osc_stage[1])
    );
    
    propagation_stage prop_stage1(
        .in(osc_stage[0]),
        .out(osc_stage[2])
    );
    
    inversion_stage inv_stage2(
        .in(osc_stage[2]),
        .out(osc_stage[3])
    );
    
    propagation_stage prop_stage2(
        .in(osc_stage[2]),
        .out(osc_stage[4])
    );
    
    // Output assignment
    assign clk_out = osc_stage[4];

endmodule

// Enable control submodule
module enable_control(
    input  wire enable,
    input  wire feedback,
    output wire stage_out
);
    assign stage_out = enable & ~feedback;
endmodule

// Inversion stage submodule
module inversion_stage(
    input  wire in,
    output wire out
);
    assign out = ~in;
endmodule

// Propagation stage submodule
module propagation_stage(
    input  wire in,
    output wire out
);
    assign out = in;
endmodule