module rom_thermometer #(parameter N=8)(
    input [2:0] val,
    output reg [N-1:0] code
);
    always @(*) begin
        code = (1 << val) - 1;
    end
endmodule
