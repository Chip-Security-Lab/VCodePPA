//SystemVerilog
// Top-level module: Hierarchical pipelined synchronized NOR with valid signaling
module SyncNor_Pipelined (
    input  wire clk,
    input  wire rst,
    input  wire a,
    input  wire b,
    input  wire in_valid,
    output reg  y,
    output reg  out_valid
);

    // Stage 1 pipeline registers
    wire a_stage1, b_stage1;
    wire valid_stage1;

    SyncNor_PipelineStage1 u_stage1 (
        .clk         (clk),
        .rst         (rst),
        .a_in        (a),
        .b_in        (b),
        .valid_in    (in_valid),
        .a_out       (a_stage1),
        .b_out       (b_stage1),
        .valid_out   (valid_stage1)
    );

    // Stage 2: NOR logic and register
    wire y_stage2;
    wire valid_stage2;

    SyncNor_PipelineStage2 u_stage2 (
        .clk         (clk),
        .rst         (rst),
        .a_in        (a_stage1),
        .b_in        (b_stage1),
        .valid_in    (valid_stage1),
        .y_out       (y_stage2),
        .valid_out   (valid_stage2)
    );

    // Stage 3: Output register
    SyncNor_PipelineOutput u_output (
        .clk         (clk),
        .rst         (rst),
        .y_in        (y_stage2),
        .valid_in    (valid_stage2),
        .y_out       (y),
        .valid_out   (out_valid)
    );

endmodule

//-----------------------------------------------------------------------------
// Stage 1: Input pipeline registers
// - Registers input signals and valid signal for pipelining
//-----------------------------------------------------------------------------
module SyncNor_PipelineStage1 (
    input  wire clk,
    input  wire rst,
    input  wire a_in,
    input  wire b_in,
    input  wire valid_in,
    output reg  a_out,
    output reg  b_out,
    output reg  valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            a_out     <= 1'b0;
            b_out     <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 2: NOR logic and pipeline register
// - Computes NOR of inputs and registers result and valid signal
//-----------------------------------------------------------------------------
module SyncNor_PipelineStage2 (
    input  wire clk,
    input  wire rst,
    input  wire a_in,
    input  wire b_in,
    input  wire valid_in,
    output reg  y_out,
    output reg  valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            y_out     <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            y_out     <= ~(a_in | b_in);
            valid_out <= valid_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 3: Output pipeline register
// - Registers the final output and valid signal
//-----------------------------------------------------------------------------
module SyncNor_PipelineOutput (
    input  wire clk,
    input  wire rst,
    input  wire y_in,
    input  wire valid_in,
    output reg  y_out,
    output reg  valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            y_out     <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            y_out     <= y_in;
            valid_out <= valid_in;
        end
    end
endmodule