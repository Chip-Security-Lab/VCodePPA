//SystemVerilog
module log_to_linear #(parameter WIDTH=8, LUT_SIZE=16)(
    input wire [WIDTH-1:0] log_in,
    output reg [WIDTH-1:0] linear_out
);

    reg [WIDTH-1:0] lut [0:LUT_SIZE-1];

    integer idx;
    initial begin
        idx = 0;
        while (idx < LUT_SIZE) begin
            // Use the CLA-based adder for shift calculation
            lut[idx] = cla_left_shift(8'd1, idx/2);
            idx = idx + 1;
        end
    end

    always @* begin
        if (log_in < LUT_SIZE)
            linear_out = lut[log_in];
        else
            linear_out = {WIDTH{1'b1}};
    end

    // 8-bit Carry Lookahead Adder for left shift calculation
    function [WIDTH-1:0] cla_left_shift;
        input [WIDTH-1:0] in_val;
        input [2:0] shift_amt;
        reg [WIDTH-1:0] shifted_val;
        begin
            shifted_val = in_val;
            if (shift_amt[2]) shifted_val = cla_adder_8b(shifted_val, shifted_val); // x2
            if (shift_amt[1]) shifted_val = cla_adder_8b(shifted_val, shifted_val); // x2 again
            if (shift_amt[0]) shifted_val = cla_adder_8b(shifted_val, shifted_val); // x2 again
            cla_left_shift = shifted_val;
        end
    endfunction

    // 8-bit Carry Lookahead Adder
    function [WIDTH-1:0] cla_adder_8b;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        reg [WIDTH:0] carry;
        reg [WIDTH-1:0] sum;
        reg [WIDTH-1:0] g, p;
        integer i;
        begin
            g = a & b; // Generate
            p = a ^ b; // Propagate
            carry[0] = 1'b0;
            for (i=0; i<WIDTH; i=i+1) begin
                carry[i+1] = g[i] | (p[i] & carry[i]);
                sum[i] = p[i] ^ carry[i];
            end
            cla_adder_8b = sum;
        end
    endfunction

endmodule