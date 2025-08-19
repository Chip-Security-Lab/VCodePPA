//SystemVerilog
module multi_context_regfile #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3
)(
    input clk,
    input [CTX_BITS-1:0] ctx_sel,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    // 新增减法器接口
    input [7:0] minuend,      // 被减数
    input [7:0] subtrahend,   // 减数
    output [7:0] difference,  // 差
    output borrow_out         // 最高位借位输出
);

// Context bank memory array
reg [DW-1:0] ctx_bank [0:(1<<CTX_BITS)-1][0:(1<<AW)-1];

// Pipeline registers
reg [CTX_BITS-1:0] ctx_sel_pipe;
reg [AW-1:0] addr_pipe;
reg wr_en_pipe;
reg [DW-1:0] din_pipe;

// Write data path with pipelined control
always @(posedge clk) begin
    ctx_sel_pipe <= ctx_sel;
    addr_pipe <= addr;
    wr_en_pipe <= wr_en;
    din_pipe <= din;
    
    if (wr_en_pipe) begin
        ctx_bank[ctx_sel_pipe][addr_pipe] <= din_pipe;
    end
end

// Read data path with two-stage pipeline
reg [DW-1:0] read_data_stage1;
reg [DW-1:0] read_data_stage2;

always @(posedge clk) begin
    read_data_stage1 <= ctx_bank[ctx_sel][addr];
    read_data_stage2 <= read_data_stage1;
end

assign dout = read_data_stage2;

// 8位先行借位减法器实现
wire [7:0] p; // 传播信号
wire [7:0] g; // 生成信号
wire [8:0] borrow; // 借位信号，包括输入借位和中间借位

// 第一步：生成传播信号p和生成信号g
assign p = minuend ^ subtrahend; // 异或，表示可能需要传播借位
assign g = ~minuend & subtrahend; // 当被减数位为0且减数位为1时生成借位

// 第二步：先行借位逻辑
assign borrow[0] = 1'b0; // 初始无借位
generate
    genvar i;
    for (i = 0; i < 8; i = i + 1) begin : borrow_logic
        assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
    end
endgenerate

// 第三步：计算最终差值
assign difference = p ^ borrow[7:0]; // 异或借位得到最终结果
assign borrow_out = borrow[8]; // 最高位借位输出

endmodule