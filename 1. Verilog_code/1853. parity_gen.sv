module parity_gen #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    output reg [WIDTH:0] data_out
);
always @(*) begin
    data_out = {data_in, ^data_in};
    if (POS == "MSB") 
        data_out = {^data_in, data_in};
end
endmodule