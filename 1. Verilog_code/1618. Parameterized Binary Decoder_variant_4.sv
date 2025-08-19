//SystemVerilog
module param_decoder_top #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 2**ADDR_WIDTH
)(
    input [ADDR_WIDTH-1:0] addr_bus,
    output [OUT_WIDTH-1:0] decoded
);

    decoder_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) decoder_core_inst (
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

    // 并行前缀解码器实现
    wire [OUT_WIDTH-1:0] pre_decode;
    wire [ADDR_WIDTH-1:0] addr_comp;
    
    // 地址比较逻辑
    genvar i;
    generate
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin : addr_compare
            assign pre_decode[i] = (addr_bus == i[ADDR_WIDTH-1:0]);
        end
    endgenerate

    // 输出寄存器
    always @(*) begin
        decoded = pre_decode;
    end

endmodule