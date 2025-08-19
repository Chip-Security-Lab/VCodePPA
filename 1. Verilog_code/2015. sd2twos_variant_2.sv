//SystemVerilog
module sd2twos #(parameter W=8)(input [W-1:0] sd, output [W:0] twos);

    // Lookup table for Twos complement conversion
    reg [W:0] twos_lut [0:(1<<W)-1];

    integer i;
    initial begin
        for (i = 0; i < (1<<W); i = i + 1) begin
            twos_lut[i] = {1'b0, i} + { {1{(i[W-1])}}, {W-1{1'b0}}, 1'b0 };
        end
    end

    assign twos = twos_lut[sd];

endmodule

module carry_select_adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);

    // Lookup table for 8-bit addition with carry-in
    reg [8:0] adder_lut [0:2*2**8*2**8-1];

    integer idx;
    initial begin
        for (idx = 0; idx < 2*2**8*2**8; idx = idx + 1) begin
            adder_lut[idx] = 9'd0;
        end
        for (integer aa = 0; aa < 256; aa = aa + 1) begin
            for (integer bb = 0; bb < 256; bb = bb + 1) begin
                for (integer cc = 0; cc < 2; cc = cc + 1) begin
                    adder_lut[{aa,bb,cc}] = aa + bb + cc;
                end
            end
        end
    end

    wire [8:0] lut_out;
    assign lut_out = adder_lut[{a,b,cin}];
    assign sum = lut_out[7:0];
    assign cout = lut_out[8];

endmodule

module ripple_carry_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);

    // 4-bit adder LUT
    reg [4:0] lut_4b [0:2*2**4*2**4-1];

    integer idx;
    initial begin
        for (idx = 0; idx < 2*2**4*2**4; idx = idx + 1) begin
            lut_4b[idx] = 5'd0;
        end
        for (integer aa = 0; aa < 16; aa = aa + 1) begin
            for (integer bb = 0; bb < 16; bb = bb + 1) begin
                for (integer cc = 0; cc < 2; cc = cc + 1) begin
                    lut_4b[{aa,bb,cc}] = aa + bb + cc;
                end
            end
        end
    end

    wire [4:0] lut_sum;
    assign lut_sum = lut_4b[{a,b,cin}];
    assign sum = lut_sum[3:0];
    assign cout = lut_sum[4];

endmodule