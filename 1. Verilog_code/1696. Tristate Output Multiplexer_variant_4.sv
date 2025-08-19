//SystemVerilog
module tristate_mux_top(
    input [15:0] input_bus_a,
    input [15:0] input_bus_b,
    input select,
    input output_enable,
    output [15:0] muxed_bus
);

    tristate_logic u_tristate_logic (
        .input_bus_a(input_bus_a),
        .input_bus_b(input_bus_b),
        .select(select),
        .output_enable(output_enable),
        .muxed_bus(muxed_bus)
    );

endmodule

module tristate_logic(
    input [15:0] input_bus_a,
    input [15:0] input_bus_b,
    input select,
    input output_enable,
    output reg [15:0] muxed_bus
);
    always @(*) begin
        if (output_enable) begin
            if (select) begin
                muxed_bus = input_bus_b;
            end else begin
                muxed_bus = input_bus_a;
            end
        end else begin
            muxed_bus = 16'bz;
        end
    end
endmodule