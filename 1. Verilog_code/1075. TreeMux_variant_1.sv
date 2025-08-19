//SystemVerilog
// Top-level module: Hierarchical Tree Mux
module TreeMux #(
    parameter DW = 8,
    parameter N  = 8
)(
    input  wire [N-1:0][DW-1:0] din,
    input  wire [$clog2(N)-1:0] sel,
    output wire [DW-1:0] dout
);

    // Internal signal for mux output
    wire [DW-1:0] mux_out;

    // Instantiate the hierarchical tree multiplexer
    TreeMuxCore #(
        .DW(DW),
        .N(N)
    ) u_treemux_core (
        .din(din),
        .sel(sel),
        .dout(mux_out)
    );

    assign dout = mux_out;

endmodule

// ---------------------------------------------------------------------------
// TreeMuxCore: Recursive Tree Multiplexer Core
// Selects one of N inputs based on sel using a tree structure
// ---------------------------------------------------------------------------
module TreeMuxCore #(
    parameter DW = 8,
    parameter N  = 8
)(
    input  wire [N-1:0][DW-1:0] din,
    input  wire [$clog2(N)-1:0] sel,
    output wire [DW-1:0] dout
);

    generate
        if (N == 1) begin : gen_one_input
            assign dout = din[0];
        end else if (N == 2) begin : gen_two_input
            // 2:1 multiplexer for base case
            Mux2to1 #(.DW(DW)) u_mux2to1 (
                .a(din[0]),
                .b(din[1]),
                .sel(sel[0]),
                .y(dout)
            );
        end else begin : gen_tree
            // Divide inputs into two halves
            localparam N_HIGH = (N+1)>>1;
            localparam N_LOW  = N>>1;

            wire [DW-1:0] dout_low;
            wire [DW-1:0] dout_high;

            // Lower half multiplexer
            TreeMuxCore #(
                .DW(DW),
                .N(N_LOW)
            ) u_treemux_low (
                .din(din[N_LOW-1:0]),
                .sel(sel[$clog2(N)-2:0]),
                .dout(dout_low)
            );

            // Upper half multiplexer
            TreeMuxCore #(
                .DW(DW),
                .N(N_HIGH)
            ) u_treemux_high (
                .din(din[N-1:N_LOW]),
                .sel(sel[$clog2(N)-2:0]),
                .dout(dout_high)
            );

            // Final selection between high and low halves
            Mux2to1 #(.DW(DW)) u_mux2to1 (
                .a(dout_low),
                .b(dout_high),
                .sel(sel[$clog2(N)-1]),
                .y(dout)
            );
        end
    endgenerate

endmodule

// ---------------------------------------------------------------------------
// Mux2to1: 2:1 Multiplexer
// Selects between input a and b based on sel
// ---------------------------------------------------------------------------
module Mux2to1 #(
    parameter DW = 8
)(
    input  wire [DW-1:0] a,
    input  wire [DW-1:0] b,
    input  wire          sel,
    output wire [DW-1:0] y
);
    reg [DW-1:0] mux_output;
    integer i;
    always @(*) begin
        for (i = 0; i < DW; i = i + 1) begin
            if (sel == 1'b0)
                mux_output[i] = a[i];
            else
                mux_output[i] = b[i];
        end
    end
    assign y = mux_output;
endmodule