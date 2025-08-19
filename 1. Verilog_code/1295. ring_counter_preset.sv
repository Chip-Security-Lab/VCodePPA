module ring_counter_preset (
    input clk, load,
    input [3:0] preset_val,
    output reg [3:0] out
);
always @(posedge clk) begin
    if (load) out <= preset_val;
    else out <= {out[0], out[3:1]};
end
endmodule
