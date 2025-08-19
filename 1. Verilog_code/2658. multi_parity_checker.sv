module multi_parity_checker (
    input [1:0] mode, // 00: no, 01: even, 10: odd, 11: invert
    input [7:0] data,
    output reg [1:0] parity
);
wire even_p = ~^data;
wire odd_p = ^data;

always @(*) begin
    case(mode)
        2'b00: parity = 2'b00;
        2'b01: parity = {even_p, 1'b0};
        2'b10: parity = {odd_p, 1'b1};
        2'b11: parity = {~odd_p, 1'b1};
    endcase
end
endmodule