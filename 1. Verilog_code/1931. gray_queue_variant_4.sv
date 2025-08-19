//SystemVerilog
`timescale 1ns/1ps
module gray_queue #(parameter DW=8) (
    input clk,
    input rst,
    input en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);
    reg [DW:0] queue_stage0;
    reg [DW:0] queue_stage1;
    reg [DW:0] queue_stage2;

    reg parity_stage0;
    reg [DW:0] gray_data_stage0;
    reg parity_stage1;
    reg [DW:0] gray_data_stage1;

    integer idx;

    // Stage 0: Compute parity and generate gray input (no register at input)
    wire [DW-1:0] din_wire;
    assign din_wire = din;

    wire parity_wire;
    assign parity_wire = ^din_wire;

    wire [DW:0] gray_input_wire;
    assign gray_input_wire = {din_wire, parity_wire};

    // Stage 1: Register parity and gray input
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            parity_stage0 <= 1'b0;
            gray_data_stage0 <= {(DW+1){1'b0}};
        end else if (en) begin
            parity_stage0 <= parity_wire;
            gray_data_stage0 <= gray_input_wire;
        end
    end

    // Stage 2: Register again for pipelining
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            parity_stage1 <= 1'b0;
            gray_data_stage1 <= {(DW+1){1'b0}};
        end else if (en) begin
            parity_stage1 <= parity_stage0;
            gray_data_stage1 <= gray_data_stage0;
        end
    end

    // Stage 3: Pipeline queue registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            queue_stage0 <= {(DW+1){1'b0}};
            queue_stage1 <= {(DW+1){1'b0}};
            queue_stage2 <= {(DW+1){1'b0}};
        end else if (en) begin
            queue_stage0 <= gray_data_stage1;
            queue_stage1 <= queue_stage0;
            queue_stage2 <= queue_stage1;
        end
    end

    // Stage 4: Output logic (dout, error)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DW{1'b0}};
            error <= 1'b0;
        end else if (en) begin
            dout <= queue_stage2[DW:1];
            error <= (^queue_stage2[DW:1]) ^ queue_stage2[0];
        end
    end

endmodule