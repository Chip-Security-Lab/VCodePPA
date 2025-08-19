//SystemVerilog

// Submodule for 2-to-1 Multiplexer Logic
module mux_logic(
    input [7:0] data0, data1,
    input sel,
    output reg [7:0] out
);
    always @(*) begin
        if (sel) begin
            out = data1;
        end else begin
            out = data0;
        end
    end
endmodule

// Top-level module
module basic_mux_2to1(
    input [7:0] data0, data1,
    input sel,
    output [7:0] out
);
    // Instance of the mux logic submodule
    mux_logic mux_inst (
        .data0(data0),
        .data1(data1),
        .sel(sel),
        .out(out)
    );
endmodule