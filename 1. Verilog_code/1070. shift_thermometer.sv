module shift_thermometer #(parameter WIDTH=8) (
    input clk, dir,
    output reg [WIDTH-1:0] therm
);
always @(posedge clk) begin
    therm <= dir ? (therm >> 1 | 8'h80) :
                  (therm << 1 | 1'b1);
end
endmodule
