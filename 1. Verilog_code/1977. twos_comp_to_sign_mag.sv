module twos_comp_to_sign_mag #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] twos_comp_in,
    output reg [WIDTH-1:0] sign_mag_out
);
    wire sign = twos_comp_in[WIDTH-1];
    wire [WIDTH-2:0] magnitude = twos_comp_in[WIDTH-2:0];
    
    always @* begin
        sign_mag_out[WIDTH-1] = sign;
        sign_mag_out[WIDTH-2:0] = sign ? (~magnitude + 1'b1) : magnitude;
    end
endmodule