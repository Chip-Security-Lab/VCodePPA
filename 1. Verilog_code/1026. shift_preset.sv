module shift_preset #(parameter W=8) (
    input clk, preset,
    input [W-1:0] preset_val,
    output reg [W-1:0] dout
);
always @(posedge clk) begin
    if(preset) dout <= preset_val;
    else dout <= {dout[W-2:0], 1'b1};
end
endmodule