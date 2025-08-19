//SystemVerilog
module decoder_paged #(PAGE_BITS=2) (
    input [7:0] addr,
    input [PAGE_BITS-1:0] page_reg,
    output reg [3:0] select
);

wire [7:0] addr_shifted;
wire [PAGE_BITS-1:0] page_diff;
wire borrow;
reg [3:0] decoded;

// 计算地址偏移
assign addr_shifted = addr >> (8 - PAGE_BITS);

// 借位减法器实现
assign {borrow, page_diff} = addr_shifted[PAGE_BITS-1:0] - page_reg;

// 解码逻辑 - 使用if-else替代条件运算符
always @* begin
    if (borrow == 1'b0) begin
        decoded = (1 << addr[7-PAGE_BITS:4]);
    end else begin
        decoded = 4'b0;
    end
end

always @* begin
    select = decoded;
end

endmodule