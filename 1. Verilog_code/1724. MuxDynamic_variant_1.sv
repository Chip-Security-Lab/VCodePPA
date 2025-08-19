//SystemVerilog
module MuxDynamic #(parameter W=8, N=4) (
    input [N*W-1:0] stream,
    input [$clog2(N)-1:0] ch_sel,
    output reg [W-1:0] active_ch
);
    always @(*) begin
        active_ch = stream[ch_sel*W +: W];
    end
endmodule