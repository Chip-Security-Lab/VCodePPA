//SystemVerilog
module multi_context_regfile #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3,
    parameter NUM_CTX = (1 << CTX_BITS)
)(
    input wire clk,
    input wire [CTX_BITS-1:0] ctx_sel,
    input wire wr_en,
    input wire [AW-1:0] addr,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout
);

    // 每个上下文使用的控制信号
    wire [NUM_CTX-1:0] ctx_wr_en;
    wire [DW-1:0] ctx_dout [0:NUM_CTX-1];
    wire [DW-1:0] dout_reg;

    // 上下文解码器实例
    ctx_decoder #(
        .CTX_BITS(CTX_BITS)
    ) decoder_inst (
        .ctx_sel(ctx_sel),
        .wr_en(wr_en),
        .ctx_wr_en(ctx_wr_en)
    );
    
    // 上下文存储库实例
    genvar i;
    generate
        for (i = 0; i < NUM_CTX; i = i + 1) begin : ctx_bank_gen
            ctx_storage #(
                .DW(DW),
                .AW(AW)
            ) storage_inst (
                .clk(clk),
                .wr_en(ctx_wr_en[i]),
                .addr(addr),
                .din(din),
                .dout(ctx_dout[i])
            );
        end
    endgenerate
    
    // 数据输出多路复用器实例
    data_mux #(
        .DW(DW),
        .CTX_BITS(CTX_BITS)
    ) mux_inst (
        .ctx_sel(ctx_sel),
        .ctx_dout(ctx_dout),
        .dout(dout_reg)
    );

    // 插入流水线寄存器以减少组合逻辑延迟
    reg [DW-1:0] dout_reg_pipeline;
    always @(posedge clk) begin
        dout_reg_pipeline <= dout_reg;
    end

    assign dout = dout_reg_pipeline;

endmodule

module ctx_decoder #(
    parameter CTX_BITS = 3,
    parameter NUM_CTX = (1 << CTX_BITS)
)(
    input wire [CTX_BITS-1:0] ctx_sel,
    input wire wr_en,
    output reg [NUM_CTX-1:0] ctx_wr_en
);
    integer j;
    
    always @(*) begin
        for (j = 0; j < NUM_CTX; j = j + 1) begin
            ctx_wr_en[j] = (ctx_sel == j) && wr_en;
        end
    end
    
endmodule

module ctx_storage #(
    parameter DW = 32,
    parameter AW = 3
)(
    input wire clk,
    input wire wr_en,
    input wire [AW-1:0] addr,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    always @(posedge clk) begin
        if (wr_en) mem[addr] <= din;
    end
    
    assign dout = mem[addr];
    
endmodule

module data_mux #(
    parameter DW = 32,
    parameter CTX_BITS = 3,
    parameter NUM_CTX = (1 << CTX_BITS)
)(
    input wire [CTX_BITS-1:0] ctx_sel,
    input wire [DW-1:0] ctx_dout [0:NUM_CTX-1],
    output wire [DW-1:0] dout
);
    assign dout = ctx_dout[ctx_sel];
    
endmodule