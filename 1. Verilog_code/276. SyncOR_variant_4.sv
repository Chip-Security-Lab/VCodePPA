//SystemVerilog
// SystemVerilog

//-----------------------------------------------------------------------------
// Stage 1 Register Pipeline
// Captures input data and valid signal into stage 1 registers
//-----------------------------------------------------------------------------
module SyncOR_PipelineStage1 #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input                   valid_in,
    input  [DATA_WIDTH-1:0] data1_in,
    input  [DATA_WIDTH-1:0] data2_in,
    output reg [DATA_WIDTH-1:0] data1_out,
    output reg [DATA_WIDTH-1:0] data2_out,
    output reg              valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data1_out <= {DATA_WIDTH{1'b0}};
            data2_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data1_out <= data1_in;
            data2_out <= data2_in;
            valid_out <= valid_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 2 OR Logic Pipeline
// Performs bitwise OR of two data inputs and pipelines the valid signal
//-----------------------------------------------------------------------------
module SyncOR_PipelineStage2 #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [DATA_WIDTH-1:0] data1_in,
    input  [DATA_WIDTH-1:0] data2_in,
    input                   valid_in,
    output reg [DATA_WIDTH-1:0] or_result_out,
    output reg              valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_out <= {DATA_WIDTH{1'b0}};
            valid_out     <= 1'b0;
        end else begin
            or_result_out <= data1_in | data2_in;
            valid_out     <= valid_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Output Register Stage
// Latches the OR result to the output
//-----------------------------------------------------------------------------
module SyncOR_PipelineOutput #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DATA_WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule

//-----------------------------------------------------------------------------
// Top-level Pipelined Synchronous OR Module
//-----------------------------------------------------------------------------
module SyncOR_Pipelined #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input                   valid_in,
    input  [DATA_WIDTH-1:0] data1_in,
    input  [DATA_WIDTH-1:0] data2_in,
    output                  valid_out,
    output [DATA_WIDTH-1:0] q_out
);

    // Internal pipeline signals
    wire [DATA_WIDTH-1:0] data1_stage1;
    wire [DATA_WIDTH-1:0] data2_stage1;
    wire                  valid_stage1;

    wire [DATA_WIDTH-1:0] or_result_stage2;
    wire                  valid_stage2;

    // Stage 1: Input Register Pipeline
    SyncOR_PipelineStage1 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_stage1 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .data1_in  (data1_in),
        .data2_in  (data2_in),
        .data1_out (data1_stage1),
        .data2_out (data2_stage1),
        .valid_out (valid_stage1)
    );

    // Stage 2: OR Logic Pipeline
    SyncOR_PipelineStage2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_stage2 (
        .clk           (clk),
        .rst_n         (rst_n),
        .data1_in      (data1_stage1),
        .data2_in      (data2_stage1),
        .valid_in      (valid_stage1),
        .or_result_out (or_result_stage2),
        .valid_out     (valid_stage2)
    );

    // Stage 3: Output Register
    SyncOR_PipelineOutput #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_output (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (or_result_stage2),
        .data_out (q_out)
    );

    // Output valid signal directly from last pipeline stage
    assign valid_out = valid_stage2;

endmodule