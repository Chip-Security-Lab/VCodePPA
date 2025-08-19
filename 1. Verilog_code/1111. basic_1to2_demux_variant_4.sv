//SystemVerilog
// Top-level hierarchical 1-to-2 pipelined demux module

module basic_1to2_demux (
    input  wire clk,                // Clock for pipelining stages
    input  wire rst_n,              // Asynchronous active-low reset
    input  wire data_in,            // Input data to be routed
    input  wire sel,                // Selection line
    output wire out0,               // Output line 0
    output wire out1                // Output line 1
);

    // Stage 1 output signals
    wire data_in_stage1;
    wire sel_stage1;

    // Stage 2 output signals
    wire out0_stage2;
    wire out1_stage2;

    // Stage 1: Input Register Pipeline
    stage1_input_register u_stage1_input_register (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_in),
        .sel_in         (sel),
        .data_in_reg    (data_in_stage1),
        .sel_reg        (sel_stage1)
    );

    // Stage 2: Demux and Output Register Pipeline
    stage2_demux_register u_stage2_demux_register (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in_reg    (data_in_stage1),
        .sel_reg        (sel_stage1),
        .out0_reg       (out0_stage2),
        .out1_reg       (out1_stage2)
    );

    // Output assignments for clear pipelined dataflow
    assign out0 = out0_stage2;
    assign out1 = out1_stage2;

endmodule

// -----------------------------------------------------------------------------
// Stage 1: Input Register Pipeline
// Latches input data and select signal to improve timing and dataflow
// -----------------------------------------------------------------------------
module stage1_input_register (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    input  wire sel_in,
    output reg  data_in_reg,
    output reg  sel_reg
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 1'b0;
            sel_reg     <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            sel_reg     <= sel_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Stage 2: Demux and Output Register Pipeline
// Decodes select signal and registers the outputs for pipelined dataflow
// -----------------------------------------------------------------------------
module stage2_demux_register (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in_reg,
    input  wire sel_reg,
    output reg  out0_reg,
    output reg  out1_reg
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_reg <= 1'b0;
            out1_reg <= 1'b0;
        end else begin
            out0_reg <= (sel_reg == 1'b0) ? data_in_reg : 1'b0;
            out1_reg <= (sel_reg == 1'b1) ? data_in_reg : 1'b0;
        end
    end
endmodule