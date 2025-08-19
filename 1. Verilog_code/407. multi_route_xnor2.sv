module multi_route_xnor2 (input1, input2, input3, output_xnor);
    input wire [7:0] input1, input2, input3;
    output reg [7:0] output_xnor;

    always @(*) begin
        output_xnor = ~(input1 ^ input2) & ~(input2 ^ input3);
    end
endmodule