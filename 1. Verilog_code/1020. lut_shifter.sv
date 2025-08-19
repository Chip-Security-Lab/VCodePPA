module lut_shifter #(parameter W=4) (
    input [W-1:0] din,
    input [1:0] shift,
    output reg [W-1:0] dout
);
always @(*) begin
    case(shift)
        0: dout = din;
        1: dout = {din[W-2:0], 1'b0};
        2: dout = {din[W-3:0], 2'b00};
        3: dout = {din[W-4:0], 3'b000};
    endcase
end
endmodule