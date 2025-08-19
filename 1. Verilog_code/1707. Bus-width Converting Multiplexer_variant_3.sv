//SystemVerilog
module width_converting_mux(
    input [31:0] wide_input,
    input [7:0] narrow_input,
    input select, mode,
    output [31:0] result
);

    wire [31:0] narrow_extended;
    wire [31:0] mux_output;

    width_extender u_width_extender(
        .narrow_input(narrow_input),
        .mode(mode),
        .extended_output(narrow_extended)
    );

    mux_2to1 u_mux_2to1(
        .wide_input(wide_input),
        .narrow_input(narrow_extended),
        .select(select),
        .result(mux_output)
    );

    assign result = mux_output;

endmodule

module width_extender(
    input [7:0] narrow_input,
    input mode,
    output reg [31:0] extended_output
);
    always @(*) begin
        extended_output = mode ? {24'b0, narrow_input} : {narrow_input, 24'b0};
    end
endmodule

module mux_2to1(
    input [31:0] wide_input,
    input [31:0] narrow_input,
    input select,
    output reg [31:0] result
);
    always @(*) begin
        result = select ? narrow_input : wide_input;
    end
endmodule