//SystemVerilog
module tristate_mux_top(
    input [15:0] input_bus_a,
    input [15:0] input_bus_b,
    input select,
    input output_enable,
    output [15:0] muxed_bus
);

    wire [15:0] mux_output;

    mux_2to1 mux_inst(
        .input_a(input_bus_a),
        .input_b(input_bus_b),
        .select(select),
        .mux_out(mux_output)
    );

    tristate_buffer tristate_inst(
        .data_in(mux_output),
        .enable(output_enable),
        .data_out(muxed_bus)
    );

endmodule

module mux_2to1(
    input [15:0] input_a,
    input [15:0] input_b,
    input select,
    output reg [15:0] mux_out
);
    always @(*) begin
        if (select) begin
            mux_out = input_b;
        end else begin
            mux_out = input_a;
        end
    end
endmodule

module tristate_buffer(
    input [15:0] data_in,
    input enable,
    output reg [15:0] data_out
);
    always @(*) begin
        if (enable) begin
            data_out = data_in;
        end else begin
            data_out = 16'bz;
        end
    end
endmodule