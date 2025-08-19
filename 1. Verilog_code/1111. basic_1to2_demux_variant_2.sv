//SystemVerilog
// Top-level 1-to-2 Demux with pipelined structure
module basic_1to2_demux (
    input  wire clk,        // Clock for pipeline
    input  wire rst_n,      // Active-low synchronous reset
    input  wire data_in,    // Input data to be routed
    input  wire sel,        // Selection line
    output wire out0,       // Output line 0
    output wire out1        // Output line 1
);

    // Stage 1: Input and selection pipeline registers
    wire data_in_stage1;
    wire sel_stage1;

    // Stage 2: Demux output pipeline registers
    wire out0_stage2;
    wire out1_stage2;

    // Input pipeline register module
    pipeline_reg #(
        .WIDTH(2)
    ) u_pipeline_reg_stage1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .din    ({data_in, sel}),
        .dout   ({data_in_stage1, sel_stage1})
    );

    // Demux logic and output pipeline register module
    demux_out_pipeline u_demux_out_pipeline (
        .clk             (clk),
        .rst_n           (rst_n),
        .data_in_piped   (data_in_stage1),
        .sel_piped       (sel_stage1),
        .out0_piped      (out0_stage2),
        .out1_piped      (out1_stage2)
    );

    // Output assignments
    assign out0 = out0_stage2;
    assign out1 = out1_stage2;

endmodule

// ---------------------------------------------------------------------------
// Module: pipeline_reg
// Function: Generic parameterized pipeline register for synchronous signals
// ---------------------------------------------------------------------------
module pipeline_reg #(
    parameter WIDTH = 1
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [WIDTH-1:0]  din,
    output reg  [WIDTH-1:0]  dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {WIDTH{1'b0}};
        end else begin
            dout <= din;
        end
    end
endmodule

// ---------------------------------------------------------------------------
// Module: demux_out_pipeline
// Function: 1-to-2 Demux logic followed by output pipeline register
// Inputs are pipelined data and sel
// ---------------------------------------------------------------------------
module demux_out_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in_piped,
    input  wire sel_piped,
    output reg  out0_piped,
    output reg  out1_piped
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_piped <= 1'b0;
            out1_piped <= 1'b0;
        end else begin
            out0_piped <= (sel_piped == 1'b0) ? data_in_piped : 1'b0;
            out1_piped <= (sel_piped == 1'b1) ? data_in_piped : 1'b0;
        end
    end
endmodule