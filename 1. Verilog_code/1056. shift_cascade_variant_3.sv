//SystemVerilog
`timescale 1ns / 1ps

module shift_stage #(
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              en,
    input  wire [WIDTH-1:0]  data_in,
    output reg  [WIDTH-1:0]  data_out
);
    always @(posedge clk) begin
        if (en) begin
            data_out <= data_in;
        end
    end
endmodule

module shift_cascade #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
)(
    input  wire              clk,
    input  wire              en,
    input  wire [WIDTH-1:0]  data_in,
    output wire [WIDTH-1:0]  data_out
);

    // Internal wires for shift stages
    wire [WIDTH-1:0] stage_out [0:DEPTH];

    assign stage_out[0] = data_in;

    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : SHIFT_CHAIN
            shift_stage #(
                .WIDTH(WIDTH)
            ) u_shift_stage (
                .clk      (clk),
                .en       (en),
                .data_in  (stage_out[i]),
                .data_out (stage_out[i+1])
            );
        end
    endgenerate

    // Select output according to original logic
    // Equivalent to original: output is selected by DEPTH bits
    // Use hierarchical mux for balanced path

    wire [WIDTH-1:0] mux_level1, mux_level2;

    assign mux_level1 = (DEPTH[0] == 1'b1) ? stage_out[1] : stage_out[0];
    assign mux_level2 = (DEPTH[1] == 1'b1) ? stage_out[2] : mux_level1;
    assign data_out   = (DEPTH[2] == 1'b1) ? stage_out[3] : mux_level2;

endmodule