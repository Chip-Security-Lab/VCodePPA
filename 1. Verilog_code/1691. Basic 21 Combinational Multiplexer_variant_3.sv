//SystemVerilog
module basic_mux_2to1(
    input [7:0] data0, data1,
    input sel,
    output [7:0] out
);

    mux_selector selector(
        .data0(data0),
        .data1(data1),
        .sel(sel),
        .out(out)
    );

endmodule

module mux_selector(
    input [7:0] data0, data1,
    input sel,
    output reg [7:0] out
);

    always @(*) begin
        case (sel)
            1'b0: out = data0;
            1'b1: out = data1;
            default: out = 8'b0;
        endcase
    end

endmodule