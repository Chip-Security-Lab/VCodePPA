module sign_mag_to_twos_comp #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] sign_mag_in,
    output reg [WIDTH-1:0] twos_comp_out
);
    wire sign = sign_mag_in[WIDTH-1];
    wire [WIDTH-2:0] magnitude = sign_mag_in[WIDTH-2:0];
    
    always @* begin
        twos_comp_out = sign ? {1'b1, (~magnitude + 1'b1)} : sign_mag_in;
    end
endmodule