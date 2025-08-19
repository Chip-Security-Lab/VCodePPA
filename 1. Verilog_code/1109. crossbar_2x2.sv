module crossbar_2x2 (
    input wire [7:0] in0, in1,    // Input ports
    input wire [1:0] select,      // Selection control (2 bits)
    output wire [7:0] out0, out1  // Output ports
);
    // select[0] controls out0, select[1] controls out1
    assign out0 = select[0] ? in1 : in0;
    assign out1 = select[1] ? in1 : in0;
endmodule