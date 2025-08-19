module ecc_regfile #(
    parameter DW = 32,
    parameter AW = 4
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output reg parity_err
);
reg [DW:0] mem [0:(1<<AW)-1]; // 额外位存储校验位
reg [DW:0] current;

always @(posedge clk) begin
    if (rst) begin
        integer i;
        for (i = 0; i < (1<<AW); i = i + 1) begin
            mem[i] <= {(DW+1){1'b0}};
        end
        parity_err <= 0;
    end else if (wr_en) begin
        mem[addr] <= {din, ^din}; // 生成校验位
    end
    
    current <= mem[addr];
    parity_err <= (^current[DW:0]) != 0; // 校验检测
end

assign dout = current[DW-1:0];
endmodule