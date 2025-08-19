//SystemVerilog
// Top-level: Hierarchical BitSliceMux
module BitSliceMux #(parameter N=4, DW=4) (
    input  [N-1:0]          sel,
    input  [(DW*N)-1:0]     din,
    output [DW-1:0]         dout
);

    // Internal wire for each bit of dout
    wire [DW-1:0] mux_out;

    genvar bit_index;
    generate
        for (bit_index = 0; bit_index < DW; bit_index = bit_index + 1) begin: gen_bit_mux
            BitSliceMux_Slice #(
                .N(N)
            ) u_bit_slice_mux (
                .sel    (sel),
                .din    (din),
                .bit_idx(bit_index),
                .dout   (mux_out[bit_index])
            );
        end
    endgenerate

    assign dout = mux_out;

endmodule

//-----------------------------------------------------------------------------
// Submodule: BitSliceMux_Slice
// Description: Selects the value of a specific data bit across N inputs
//              based on select signals, and outputs the OR-reduced result.
//-----------------------------------------------------------------------------
module BitSliceMux_Slice #(parameter N=4) (
    input      [N-1:0]      sel,
    input      [(N*32)-1:0] din, // Maximum DW up to 32 bits for parameterization; unused bits ignored
    input      [$clog2(32)-1:0] bit_idx, // Supports up to DW=32
    output reg              dout
);
    integer select_index;
    reg [N-1:0] bit_select;

    always @* begin
        select_index = 0;
        while (select_index < N) begin
            bit_select[select_index] = din[(select_index*32) + bit_idx] & sel[select_index];
            select_index = select_index + 1;
        end
        dout = |bit_select;
    end
endmodule