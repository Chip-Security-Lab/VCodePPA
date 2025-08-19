module mux_8to1_indexed (
    input wire [7:0] inputs,      // 8 data inputs
    input wire [2:0] selector,    // 3-bit selector
    output wire out               // Output
);
    // Direct bit selection approach
    assign out = inputs[selector];
endmodule