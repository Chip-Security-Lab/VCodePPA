module struct_input_xnor (
    input [3:0] a_in,
    input [3:0] b_in,
    output [3:0] struct_out
);
    // Replace struct with standard port declarations
    assign struct_out = ~(a_in ^ b_in);
endmodule