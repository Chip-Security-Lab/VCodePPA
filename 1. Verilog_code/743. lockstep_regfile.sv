module lockstep_regfile #(
    parameter DW = 18,
    parameter AW = 4
)(
    input clk,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output error
);
reg [DW-1:0] bank0 [0:15];
reg [DW-1:0] bank1 [0:15];

always @(posedge clk) begin
    if (wr_en) begin
        bank0[addr] <= din;
        bank1[addr] <= din; // 同步写入
    end
end

assign dout = bank0[addr];
assign error = (bank0[addr] != bank1[addr]); // 一致性检查
endmodule