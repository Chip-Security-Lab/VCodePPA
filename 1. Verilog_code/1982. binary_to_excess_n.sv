module binary_to_excess_n #(parameter WIDTH=8, N=127)(
    input wire [WIDTH-1:0] binary_in,
    output reg [WIDTH-1:0] excess_n_out
);
    always @* begin
        excess_n_out = binary_in + N;
    end
endmodule