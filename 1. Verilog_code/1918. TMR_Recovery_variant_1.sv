//SystemVerilog
// Top-level TMR Recovery module with hierarchical submodules
module TMR_Recovery #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] ch0,
    input  [WIDTH-1:0] ch1,
    input  [WIDTH-1:0] ch2,
    output [WIDTH-1:0] data_out
);

    // Internal signals for submodule interconnection
    wire [WIDTH-1:0] or_ch0_ch2;
    wire [WIDTH-1:0] and_ch1_or;
    wire [WIDTH-1:0] and_ch0_ch2;

    // Submodule: OR gate for ch0 and ch2
    TMR_Or #(.WIDTH(WIDTH)) u_or_ch0_ch2 (
        .in0(ch0),
        .in1(ch2),
        .or_out(or_ch0_ch2)
    );

    // Submodule: AND gate for ch1 and (ch0 | ch2)
    TMR_And #(.WIDTH(WIDTH)) u_and_ch1_or (
        .in0(ch1),
        .in1(or_ch0_ch2),
        .and_out(and_ch1_or)
    );

    // Submodule: AND gate for ch0 and ch2
    TMR_And #(.WIDTH(WIDTH)) u_and_ch0_ch2 (
        .in0(ch0),
        .in1(ch2),
        .and_out(and_ch0_ch2)
    );

    // Submodule: OR gate for final data_out
    TMR_Or #(.WIDTH(WIDTH)) u_or_final (
        .in0(and_ch1_or),
        .in1(and_ch0_ch2),
        .or_out(data_out)
    );

endmodule

// Submodule: Bitwise OR operation
// Performs bitwise OR between in0 and in1
module TMR_Or #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    output [WIDTH-1:0] or_out
);
    assign or_out = in0 | in1;
endmodule

// Submodule: Bitwise AND operation
// Performs bitwise AND between in0 and in1
module TMR_And #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    output [WIDTH-1:0] and_out
);
    assign and_out = in0 & in1;
endmodule