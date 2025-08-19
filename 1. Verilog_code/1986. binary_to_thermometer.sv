module binary_to_thermometer #(parameter BINARY_WIDTH=3)(
    input wire [BINARY_WIDTH-1:0] binary_in,
    output reg [2**BINARY_WIDTH-2:0] thermo_out
);
    integer i;
    
    always @* begin
        for (i = 0; i < 2**BINARY_WIDTH-1; i = i + 1) begin
            thermo_out[i] = (i < binary_in) ? 1'b1 : 1'b0;
        end
    end
endmodule