module decoder_multi_protocol (
    input mode,
    input [15:0] addr,
    output reg [3:0] sel
);
    always @(*) begin
        case(mode)
            0: sel = (addr[15:12] == 4'ha) ? addr[3:0] : 0; // 模式0：高4位匹配
            1: sel = (addr[7:4] == 4'h5) ? addr[3:0] : 0;   // 模式1：中间4位匹配
        endcase
    end
endmodule