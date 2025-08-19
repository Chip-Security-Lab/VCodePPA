module MuxBusHold #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output reg [W-1:0] bus_out
);
always @(*) begin
    if (!hold) bus_out = bus_in[sel];
end
endmodule