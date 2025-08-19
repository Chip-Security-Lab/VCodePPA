//SystemVerilog
module binary_to_thermometer #(parameter BINARY_WIDTH=3)(
    input wire [BINARY_WIDTH-1:0] binary_in,
    output reg [2**BINARY_WIDTH-2:0] thermo_out
);
    integer idx;
    reg [2**BINARY_WIDTH-2:0] mask;
    reg [BINARY_WIDTH-1:0] subtrahend;
    reg [BINARY_WIDTH-1:0] twos_complement;
    reg [BINARY_WIDTH-1:0] add_result;

    always @* begin
        if (binary_in == 0) begin
            thermo_out = { (2**BINARY_WIDTH-1){1'b0} };
        end else begin
            // Use two's complement addition for subtraction: (2**BINARY_WIDTH-1) - binary_in
            subtrahend = binary_in;
            twos_complement = (~subtrahend) + 1'b1;
            add_result = (2**BINARY_WIDTH-1) + twos_complement;
            mask = { (2**BINARY_WIDTH-1){1'b1} } >> add_result;
            thermo_out = mask;
        end
    end
endmodule