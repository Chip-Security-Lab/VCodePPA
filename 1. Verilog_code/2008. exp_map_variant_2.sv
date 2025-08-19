//SystemVerilog
module exp_map #(parameter W = 16)(input [W-1:0] x, output [W-1:0] y);

    wire [W-5:0] shift_amt;
    wire [3:0] low_bits;
    wire [W-1:0] one_shifted;
    wire [W-1:0] low_shifted;
    wire [W-1:0] y_sum;

    assign shift_amt = x[W-1:4];
    assign low_bits = x[3:0];

    // Barrel shifter for (1 << shift_amt)
    function [W-1:0] barrel_shift_one;
        input [W-5:0] s;
        integer i;
        reg [W-1:0] tmp;
        begin
            tmp = 1;
            for (i = 0; i < W-4; i = i + 1) begin
                if (s[i])
                    tmp = tmp << (1 << i);
            end
            barrel_shift_one = tmp;
        end
    endfunction

    // Barrel shifter for (low_bits << (shift_amt - 4))
    function [W-1:0] barrel_shift_low;
        input [3:0] data;
        input [W-5:0] s;
        integer i;
        reg [W-1:0] tmp;
        reg [W-5:0] shift_val;
        begin
            // Limit shift amount to 0 if s < 4
            if (s < 4)
                shift_val = 0;
            else
                shift_val = s - 4;
            tmp = {{(W-4){1'b0}}, data};
            for (i = 0; i < W-4; i = i + 1) begin
                if (shift_val[i])
                    tmp = tmp << (1 << i);
            end
            barrel_shift_low = tmp;
        end
    endfunction

    assign one_shifted = barrel_shift_one(shift_amt);
    assign low_shifted = barrel_shift_low(low_bits, shift_amt);
    assign y_sum = one_shifted + low_shifted;
    assign y = y_sum;

endmodule