//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: BitSliceMux
// Optimized N-to-1 multiplexer for DW-bit wide buses.
//-----------------------------------------------------------------------------
module BitSliceMux #(
    parameter N = 4,   // Number of inputs
    parameter DW = 4   // Data width per input
)(
    input  [N-1:0]                 sel,
    input  [(DW*N)-1:0]            din,
    output [DW-1:0]                dout
);

    reg [DW-1:0] mux_out;
    integer i, j;

    always @(*) begin
        mux_out = {DW{1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            if (sel[i]) begin
                for (j = 0; j < DW; j = j + 1) begin
                    mux_out[j] = din[(i*DW)+j];
                end
            end
        end
    end

    assign dout = mux_out;

endmodule

//-----------------------------------------------------------------------------
// Submodule: BitSliceMux_bit
// Optimized single-bit N-to-1 multiplexer.
//-----------------------------------------------------------------------------
module BitSliceMux_bit #(
    parameter N = 4
)(
    input  [N-1:0] sel,           // Selection signals for N inputs
    input  [N-1:0] din_per_bit,   // N bits, each from same bit position of each input
    output         dout           // Output for this bit position
);

    reg mux_bit;
    integer k;

    always @(*) begin
        mux_bit = 1'b0;
        for (k = 0; k < N; k = k + 1) begin
            if (sel[k])
                mux_bit = din_per_bit[k];
        end
    end

    assign dout = mux_bit;

endmodule