//SystemVerilog
module multi_bit_lfsr (
    input clk,
    input rst,
    output [19:0] rnd_out
);
    reg [19:0] lfsr;
    wire [3:0] taps;

    // 通过布尔代数恒等式简化异或表达式
    // a ^ b = (a & ~b) | (~a & b)
    assign taps[3] = (lfsr[7]  & ~lfsr[0])  | (~lfsr[7]  & lfsr[0]);
    assign taps[2] = (lfsr[11] & ~lfsr[8])  | (~lfsr[11] & lfsr[8]);
    assign taps[1] = (lfsr[15] & ~lfsr[12]) | (~lfsr[15] & lfsr[12]);
    assign taps[0] = (lfsr[19] & ~lfsr[16]) | (~lfsr[19] & lfsr[16]);

    always @(posedge clk) begin
        if (rst)
            lfsr <= 20'hFACEB;
        else
            lfsr <= {lfsr[15:0], taps};
    end

    assign rnd_out = lfsr;
endmodule