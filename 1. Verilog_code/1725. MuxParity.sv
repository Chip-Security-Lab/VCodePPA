module MuxParity #(parameter W=8) (
    input [3:0][W:0] data_ch, // [W] is parity
    input [1:0] sel,
    output reg [W:0] data_out
);
always @(*) begin
    data_out = data_ch[sel];
    data_out[W] = ^data_out[W-1:0];
end
endmodule