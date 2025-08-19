//SystemVerilog
module hybrid_regfile_pipeline #(
    parameter TRIGGER_DEPTH = 8,
    parameter RAM_DEPTH = 24
)(
    input clk,
    input wr_en,
    input [7:0] addr,
    input [31:0] din,
    output reg [31:0] dout_stage1,
    output reg [31:0] dout_stage2
);

// 低地址使用触发器
reg [31:0] trigger_bank [0:TRIGGER_DEPTH-1];

// 高地址使用RAM（行为级模型）
reg [31:0] ram_bank [TRIGGER_DEPTH:TRIGGER_DEPTH+RAM_DEPTH-1];

// 中间寄存器
reg [31:0] din_stage1;
reg [7:0] addr_stage1;
reg [7:0] addr_stage1_buf1;
reg [7:0] addr_stage1_buf2;
reg wr_en_stage1;

// 曼彻斯特进位链加法器信号
wire [31:0] addr_incremented;
wire [31:0] a, b;
wire [31:0] p, g; // 传播和生成信号
wire [32:0] c;    // 进位信号，多一位

// 加法器输入
assign a = {24'b0, addr_stage1};
assign b = 32'b1; // 加1操作

// 第一阶段：计算传播和生成信号
assign p = a ^ b;  // 传播信号
assign g = a & b;  // 生成信号

// 第二阶段：曼彻斯特进位链计算
assign c[0] = 1'b0; // 初始进位为0

// 生成中间进位信号
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : carry_chain
        assign c[i+1] = g[i] | (p[i] & c[i]);
    end
endgenerate

// 最终加法结果
assign addr_incremented = p ^ c[31:0];

// 地址缓冲寄存器
always @(posedge clk) begin
    addr_stage1_buf1 <= addr_stage1;
    addr_stage1_buf2 <= addr_stage1_buf1;
end

always @(posedge clk) begin
    // 第一阶段：接收输入
    din_stage1 <= din;
    addr_stage1 <= addr;
    wr_en_stage1 <= wr_en;
end

always @(posedge clk) begin
    // 第二阶段：写入寄存器
    if (wr_en_stage1) begin
        if (addr_stage1 < TRIGGER_DEPTH)
            trigger_bank[addr_stage1] <= din_stage1;
        else if (addr_stage1 < TRIGGER_DEPTH + RAM_DEPTH)
            ram_bank[addr_stage1] <= din_stage1;
    end
end

always @(posedge clk) begin
    // 第三阶段：输出数据
    if (addr_stage1_buf2 < TRIGGER_DEPTH) 
        dout_stage1 <= trigger_bank[addr_stage1_buf2];
    else 
        dout_stage1 <= ram_bank[addr_stage1_buf2];
end

always @(posedge clk) begin
    // 第四阶段：更新最终输出
    dout_stage2 <= dout_stage1;
end

endmodule