module shadow_regfile #(
    parameter DW = 24,
    parameter AW = 3
)(
    input clk,
    input swap,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] active_bank [0:7];
reg [DW-1:0] shadow_bank [0:7];
reg bank_sel;

// 主bank操作
always @(posedge clk) begin
    if (wr_en) begin
        active_bank[addr] <= din;
    end
    if (swap) begin
        active_bank <= shadow_bank;
        bank_sel <= ~bank_sel;
    end
end

// 影子bank后台更新
always @(negedge clk) begin
    shadow_bank <= active_bank;
end

assign dout = active_bank[addr];
endmodule