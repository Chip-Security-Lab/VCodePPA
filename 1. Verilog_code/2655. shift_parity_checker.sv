module shift_parity_checker (
    input clk, serial_in,
    output reg parity
);
reg [7:0] shift_reg;

always @(posedge clk) begin
    shift_reg <= {shift_reg[6:0], serial_in};
    parity <= ^shift_reg;
end
endmodule