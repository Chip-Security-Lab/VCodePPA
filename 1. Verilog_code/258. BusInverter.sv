module BusInverter(
    input [63:0] bus_input,
    output [63:0] inverted_bus
);
    genvar i;
    generate
        for(i=0; i<64; i=i+1) begin : BIT_INV
            assign inverted_bus[i] = ~bus_input[i];
        end
    endgenerate
endmodule
