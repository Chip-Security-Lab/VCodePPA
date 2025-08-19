//SystemVerilog

// Counter module: Generates a time-division multiplexing selector
module tdm_counter #(
    parameter SELW = 2
)(
    input  wire              clk,
    input  wire              rst,
    output reg  [SELW-1:0]   sel
);
    // sel: current channel selector
    always @(posedge clk) begin
        if (rst)
            sel <= {SELW{1'b0}};
        else
            sel <= sel + {{(SELW-1){1'b0}}, 1'b1};
    end
endmodule

// Multiplexer module: Selects one of the input channels based on selector
module tdm_mux #(
    parameter DW = 8,
    parameter SELW = 2
)(
    input  wire [3:0][DW-1:0]   ch,    // Input channel bus
    input  wire [SELW-1:0]      sel,   // Channel selector
    output reg  [DW-1:0]        mux_out // Selected channel output
);
    // mux_out: output of selected channel
    always @* begin
        mux_out = ch[sel];
    end
endmodule

// Output Register module: Registers the mux output
module tdm_output_reg #(
    parameter DW = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire [DW-1:0] data_in,
    output reg  [DW-1:0] data_out
);
    // data_out: registered output
    always @(posedge clk) begin
        if (rst)
            data_out <= {DW{1'b0}};
        else
            data_out <= data_in;
    end
endmodule

// Top-level Time Division Multiplexer module
module TimeDivMux #(
    parameter DW = 8
)(
    input  wire              clk,
    input  wire              rst,
    input  wire [3:0][DW-1:0] ch,
    output wire [DW-1:0]     out
);
    // Internal signals
    wire [1:0]      sel;
    wire [DW-1:0]   mux_out;

    // Channel select counter instance
    tdm_counter #(
        .SELW(2)
    ) u_counter (
        .clk (clk),
        .rst (rst),
        .sel (sel)
    );

    // Multiplexer instance
    tdm_mux #(
        .DW(DW),
        .SELW(2)
    ) u_mux (
        .ch      (ch),
        .sel     (sel),
        .mux_out (mux_out)
    );

    // Output register instance
    tdm_output_reg #(
        .DW(DW)
    ) u_output_reg (
        .clk     (clk),
        .rst     (rst),
        .data_in (mux_out),
        .data_out(out)
    );

endmodule