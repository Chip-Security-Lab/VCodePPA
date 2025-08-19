//SystemVerilog
`timescale 1ns / 1ps
module shift_cascade_pipeline #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
)(
    input clk,
    input rst_n,
    input en,
    input [WIDTH-1:0] data_in,
    input valid_in,
    output [WIDTH-1:0] data_out,
    output valid_out
);

    // Reduced pipeline depth: merge adjacent lightweight stages
    // For DEPTH == 4, merge stages 1+2 and 3+4 into two stages
    // For DEPTH == 3, merge stages 1+2 and keep stage 3
    // For DEPTH == 2 or 1, keep as is

    reg [WIDTH-1:0] data_stageA;
    reg [WIDTH-1:0] data_stageB;
    reg valid_stageA;
    reg valid_stageB;

    // Output assignment wires
    wire [WIDTH-1:0] data_out_w;
    wire valid_out_w;

    // Pipeline flush logic
    wire flush;
    assign flush = ~rst_n;

    generate
        if (DEPTH == 1) begin : gen_depth1
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    data_stageA <= {WIDTH{1'b0}};
                    valid_stageA <= 1'b0;
                end else if (en) begin
                    data_stageA <= data_in;
                    valid_stageA <= valid_in;
                end
            end
            assign data_out_w = data_stageA;
            assign valid_out_w = valid_stageA;
        end else if (DEPTH == 2) begin : gen_depth2
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    data_stageA <= {WIDTH{1'b0}};
                    valid_stageA <= 1'b0;
                    data_stageB <= {WIDTH{1'b0}};
                    valid_stageB <= 1'b0;
                end else if (en) begin
                    data_stageA <= data_in;
                    valid_stageA <= valid_in;
                    data_stageB <= data_stageA;
                    valid_stageB <= valid_stageA;
                end
            end
            assign data_out_w = data_stageB;
            assign valid_out_w = valid_stageB;
        end else if (DEPTH == 3) begin : gen_depth3
            // Merge stages 1+2, keep stage 3
            reg [WIDTH-1:0] data_stageC;
            reg valid_stageC;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    data_stageA <= {WIDTH{1'b0}};
                    valid_stageA <= 1'b0;
                    data_stageB <= {WIDTH{1'b0}};
                    valid_stageB <= 1'b0;
                    data_stageC <= {WIDTH{1'b0}};
                    valid_stageC <= 1'b0;
                end else if (en) begin
                    // StageA: merge 1+2
                    data_stageA <= data_in;
                    valid_stageA <= valid_in;
                    data_stageB <= data_stageA;
                    valid_stageB <= valid_stageA;
                    // StageC: original stage3
                    data_stageC <= data_stageB;
                    valid_stageC <= valid_stageB;
                end
            end
            assign data_out_w = data_stageC;
            assign valid_out_w = valid_stageC;
        end else begin : gen_depth4
            // DEPTH >=4 , merge (1+2) and (3+4) into two stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    data_stageA <= {WIDTH{1'b0}};
                    valid_stageA <= 1'b0;
                    data_stageB <= {WIDTH{1'b0}};
                    valid_stageB <= 1'b0;
                end else if (en) begin
                    // StageA: merge 1+2
                    data_stageA <= data_in;
                    valid_stageA <= valid_in;
                    // StageB: merge 3+4
                    data_stageB <= data_stageA;
                    valid_stageB <= valid_stageA;
                end
            end
            assign data_out_w = data_stageB;
            assign valid_out_w = valid_stageB;
        end
    endgenerate

    assign data_out = data_out_w;
    assign valid_out = valid_out_w;

endmodule