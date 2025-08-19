module hotswap_regfile #(
    parameter DW = 28,
    parameter AW = 5,
    parameter DEFAULT_VAL = 32'hDEADBEEF
)(
    input clk,
    input rst_n,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] din,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] dout,
    // 热插拔控制接口
    input [31:0] reg_enable    // 每个bit对应寄存器的使能状态
);
reg [DW-1:0] mem [0:(1<<AW)-1];
wire wr_en_gated = wr_en && reg_enable[wr_addr];

always @(posedge clk) begin
    if (!rst_n) begin
        integer i;
        for (i = 0; i < (1<<AW); i = i + 1) begin
            mem[i] <= DEFAULT_VAL;
        end
    end else if (wr_en_gated) begin
        mem[wr_addr] <= din;
    end
end

assign dout = reg_enable[rd_addr] ? mem[rd_addr] : DEFAULT_VAL;
endmodule