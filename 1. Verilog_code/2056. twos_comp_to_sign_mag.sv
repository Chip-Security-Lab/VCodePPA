module twos_comp_to_sign_mag #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] twos_comp_in,
    output wire [WIDTH-1:0] sign_mag_out
);
    wire sign;
    wire [WIDTH-2:0] magnitude;
    
    assign sign = twos_comp_in[WIDTH-1];
    assign magnitude = sign ? (~twos_comp_in[WIDTH-2:0] + 1'b1) : twos_comp_in[WIDTH-2:0];
    assign sign_mag_out = {sign, magnitude};
endmodule