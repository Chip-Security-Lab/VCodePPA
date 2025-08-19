module thermometer_to_binary #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] thermo_in,
    output reg [$clog2(WIDTH):0] binary_out
);
    integer count;
    integer j;
    
    always @(*) begin
        count = 0;
        for (j = 0; j < WIDTH; j = j + 1)
            count = count + thermo_in[j];
        binary_out = count;
    end
endmodule