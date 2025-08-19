module excess_n_to_binary #(parameter WIDTH=8, N=127)(
    input wire [WIDTH-1:0] excess_n_in,
    output reg [WIDTH-1:0] binary_out
);
    always @* begin
        binary_out = excess_n_in - N;
    end
endmodule