//SystemVerilog
module karatsuba_mult_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] result
);

    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z1, z2;
    wire [8:0] z1_temp;
    wire [4:0] sum_a, sum_b;
    wire [8:0] prod_sum;
    
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;
    assign prod_sum = sum_a * sum_b;
    assign z1_temp = prod_sum - z0 - z2;
    assign z1 = z1_temp[7:0];
    
    assign result = (z2 << 8) + (z1 << 4) + z0;
    
endmodule

module d_latch_sync_preset (
    input wire d,
    input wire enable,
    input wire preset,
    output reg q
);
    always @* begin
        if (enable && preset)
            q = 1'b1;
        else if (enable)
            q = d;
    end
endmodule