//SystemVerilog
module MuxDynamic #(parameter W=8, N=4) (
    input [N*W-1:0] stream,
    input [$clog2(N)-1:0] ch_sel,
    output reg [W-1:0] active_ch
);
    always @(*) begin
        case(ch_sel)
            0: active_ch = stream[0*W +: W];
            1: active_ch = stream[1*W +: W];
            2: active_ch = stream[2*W +: W];
            3: active_ch = stream[3*W +: W];
            default: active_ch = '0;
        endcase
    end
endmodule