//SystemVerilog
// Top-level DigitalPLL module, hierarchically structured
module DigitalPLL #(parameter NCO_WIDTH=24) (
    input clk_ref,
    input data_edge,
    output recovered_clk
);

    // Internal signals
    wire [NCO_WIDTH-1:0] phase_accum;
    wire [NCO_WIDTH-1:0] phase_step;
    wire [NCO_WIDTH-1:0] next_phase_step;
    wire phase_step_update;

    // Phase Step Controller: Adjusts phase_step based on data_edge
    PhaseStepController #(.NCO_WIDTH(NCO_WIDTH)) u_phase_step_ctrl (
        .clk_ref(clk_ref),
        .data_edge(data_edge),
        .phase_step_in(phase_step),
        .phase_step_out(next_phase_step),
        .update(phase_step_update)
    );

    // NCO Core: Phase accumulator and recovered clock generation
    NCOCore #(.NCO_WIDTH(NCO_WIDTH)) u_nco_core (
        .clk_ref(clk_ref),
        .phase_step(next_phase_step),
        .phase_accum(phase_accum),
        .recovered_clk(recovered_clk)
    );

    // Phase Step Register: Holds current phase_step value
    PhaseStepReg #(.NCO_WIDTH(NCO_WIDTH)) u_phase_step_reg (
        .clk_ref(clk_ref),
        .phase_step_in(next_phase_step),
        .update(phase_step_update),
        .phase_step_out(phase_step)
    );

endmodule

// -----------------------------------------------------------------------
// PhaseStepController: Adjusts the phase step based on incoming data edges
// Optimized: Single assignment, direct range checking, and no unnecessary chain
// -----------------------------------------------------------------------
module PhaseStepController #(parameter NCO_WIDTH=24) (
    input clk_ref,
    input data_edge,
    input [NCO_WIDTH-1:0] phase_step_in,
    output reg [NCO_WIDTH-1:0] phase_step_out,
    output reg update
);
    always @(posedge clk_ref) begin
        // Efficiently update phase_step and update flag
        {phase_step_out, update} <= data_edge ? {phase_step_in + {{(NCO_WIDTH-1){1'b0}}, 1'b1}, 1'b1} 
                                              : {phase_step_in, 1'b0};
    end
endmodule

// -----------------------------------------------------------------------
// PhaseStepReg: Holds the current phase_step value, updates on 'update'
// Optimized: Direct update with initialization and no unnecessary logic
// -----------------------------------------------------------------------
module PhaseStepReg #(parameter NCO_WIDTH=24) (
    input clk_ref,
    input [NCO_WIDTH-1:0] phase_step_in,
    input update,
    output reg [NCO_WIDTH-1:0] phase_step_out
);
    initial phase_step_out = 24'h100000;
    always @(posedge clk_ref) begin
        if (update)
            phase_step_out <= phase_step_in;
    end
endmodule

// -----------------------------------------------------------------------
// NCOCore: Numerically Controlled Oscillator core
// Optimized: Efficient accumulator and output assignment
// -----------------------------------------------------------------------
module NCOCore #(parameter NCO_WIDTH=24) (
    input clk_ref,
    input [NCO_WIDTH-1:0] phase_step,
    output reg [NCO_WIDTH-1:0] phase_accum,
    output reg recovered_clk
);
    always @(posedge clk_ref) begin
        phase_accum <= phase_accum + phase_step;
        recovered_clk <= phase_accum[NCO_WIDTH-1];
    end
endmodule