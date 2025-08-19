module dff_preset (
    input clk, preset,
    input d,
    output reg q
);
always @(posedge clk) begin
    if (preset) q <= 1'b1;
    else        q <= d;
end
endmodule