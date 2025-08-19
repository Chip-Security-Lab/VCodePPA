module lut_parity (
    input [3:0] data,
    output reg parity
);
always @(*) begin
    case(data)
        4'h0,4'h3,4'h5,4'h6,4'h9,4'hA,0'hC,4'hF: parity = 0;
        default: parity = 1;
    endcase
end
endmodule