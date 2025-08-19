//SystemVerilog
module param_decoder #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 2**ADDR_WIDTH
)(
    input [ADDR_WIDTH-1:0] addr_bus,
    output [OUT_WIDTH-1:0] decoded
);

    // 实例化解码器核心模块
    decoder_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_decoder_core (
        .addr_bus(addr_bus),
        .decoded(decoded)
    );

endmodule

module decoder_core #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 2**ADDR_WIDTH
)(
    input [ADDR_WIDTH-1:0] addr_bus,
    output reg [OUT_WIDTH-1:0] decoded
);

    // 使用generate块优化解码逻辑
    genvar i;
    generate
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin : decode_gen
            always @(*) begin
                decoded[i] = (i == addr_bus) ? 1'b1 : 1'b0;
            end
        end
    endgenerate

endmodule