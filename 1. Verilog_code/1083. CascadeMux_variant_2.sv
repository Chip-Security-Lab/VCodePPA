//SystemVerilog
// Top-level module: CascadeMux
// Hierarchically structured for clarity and modularity
module CascadeMux #(parameter DW=8) (
    input  [1:0] sel1,
    input  [1:0] sel2,
    input  [3:0][DW-1:0] stage1,
    input  [3:0][DW-1:0] stage2,
    output [DW-1:0] out
);

    wire [DW-1:0] stage1_mux_out;
    wire [DW-1:0] stage2_mux_out;

    // Stage1 multiplexer: selects one of four inputs from stage1
    StageMux #(.DW(DW)) u_stage1_mux (
        .data_in(stage1),
        .sel(sel1),
        .mux_out(stage1_mux_out)
    );

    // Stage2 multiplexer: selects one of four inputs from stage2
    StageMux #(.DW(DW)) u_stage2_mux (
        .data_in(stage2),
        .sel(sel2),
        .mux_out(stage2_mux_out)
    );

    // Output selector: chooses between stage1_mux_out and stage2_mux_out based on sel1[0]
    OutputSelector #(.DW(DW)) u_output_selector (
        .sel_bit(sel1[0]),
        .in0(stage1_mux_out),
        .in1(stage2_mux_out),
        .out(out)
    );

endmodule

// Submodule: StageMux
// 4-to-1 multiplexer for data word selection
module StageMux #(parameter DW=8) (
    input  [3:0][DW-1:0] data_in,
    input  [1:0]         sel,
    output [DW-1:0]      mux_out
);
    assign mux_out = data_in[sel];
endmodule

// Submodule: OutputSelector
// Selects between two data words based on a single bit select
module OutputSelector #(parameter DW=8) (
    input        sel_bit,
    input [DW-1:0] in0,
    input [DW-1:0] in1,
    output [DW-1:0] out
);
    // For 4-bit operation, DW must be 4
    generate
        if (DW == 4) begin : gen_subtractor
            wire [3:0] twos_complement_in1;
            wire [3:0] adder_sum;
            assign twos_complement_in1 = ~in1 + 4'b0001;
            assign adder_sum = in0 + twos_complement_in1;
            assign out = sel_bit ? adder_sum : in0;
        end else begin : gen_default
            assign out = sel_bit ? in1 : in0;
        end
    endgenerate
endmodule