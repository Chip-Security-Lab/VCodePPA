module LFSR_Shifter #(parameter WIDTH=8, TAPS=8'b10001110) (
    input clk, rst,
    output serial_out // 移除reg
);
reg [WIDTH-1:0] lfsr;
reg out_bit; // 添加中间寄存器

always @(posedge clk or posedge rst) begin
    if (rst) begin
        lfsr <= {WIDTH{1'b1}};
        out_bit <= 1'b1;
    end else begin
        lfsr <= {lfsr[WIDTH-2:0], ^(lfsr & TAPS)};
        out_bit <= lfsr[WIDTH-1];
    end
end

assign serial_out = out_bit;
endmodule