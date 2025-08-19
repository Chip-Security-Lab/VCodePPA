//SystemVerilog
// Top-level 2x2 crossbar module, hierarchically structured
module crossbar_2x2 (
    input wire [7:0] in0,
    input wire [7:0] in1,
    input wire [1:0] select,
    output wire [7:0] out0,
    output wire [7:0] out1
);

    // Submodule output wires
    wire [7:0] mux0_out;
    wire [7:0] mux1_out;

    // Instantiate 8-bit mux for out0
    crossbar_mux8 u_mux0 (
        .data0  (in0),
        .data1  (in1),
        .sel    (select[0]),
        .mux_out(mux0_out)
    );

    // Instantiate 8-bit mux for out1
    crossbar_mux8 u_mux1 (
        .data0  (in0),
        .data1  (in1),
        .sel    (select[1]),
        .mux_out(mux1_out)
    );

    assign out0 = mux0_out;
    assign out1 = mux1_out;

endmodule

// ------------------------------------------------------------------
// 8-bit 2:1 multiplexer for crossbar output selection
// ------------------------------------------------------------------
module crossbar_mux8 (
    input  wire [7:0] data0,   // 8-bit input 0
    input  wire [7:0] data1,   // 8-bit input 1
    input  wire       sel,     // Selection signal
    output wire [7:0] mux_out  // 8-bit output
);
    reg [7:0] mux_out_reg;

    always @(*) begin
        if (sel) begin
            mux_out_reg = data1;
        end else begin
            mux_out_reg = data0;
        end
    end

    assign mux_out = mux_out_reg;
endmodule