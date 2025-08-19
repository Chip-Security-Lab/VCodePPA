//SystemVerilog
module MuxParity #(parameter W=8) (
    input [3:0][W:0] data_ch, // [W] is parity
    input [1:0] sel,
    output reg [W:0] data_out
);

// Barrel shifter implementation for Karatsuba multiplier
function [7:0] karatsuba_mult;
    input [3:0] a, b;
    reg [1:0] a_high, a_low, b_high, b_low;
    reg [3:0] z0, z1, z2;
    reg [3:0] temp1, temp2;
    reg [7:0] result;
    begin
        a_high = a[3:2];
        a_low = a[1:0];
        b_high = b[3:2];
        b_low = b[1:0];
        
        z0 = a_low * b_low;
        z2 = a_high * b_high;
        temp1 = a_high + a_low;
        temp2 = b_high + b_low;
        z1 = temp1 * temp2 - z0 - z2;
        
        // Barrel shifter implementation
        result = z0;
        result = (z1 << 2) | result;
        result = (z2 << 4) | result;
        karatsuba_mult = result;
    end
endfunction

// Modified parity calculation using Karatsuba
always @(*) begin
    data_out = data_ch[sel];
    data_out[W] = ^karatsuba_mult(data_out[W-1:W-4], 4'b1111);
end

endmodule