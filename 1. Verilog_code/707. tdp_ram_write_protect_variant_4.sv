//SystemVerilog
module tdp_ram_write_protect #(
    parameter DW = 20,
    parameter AW = 8
)(
    input clk,
    input [AW-1:0] protect_start,
    input [AW-1:0] protect_end,
    // Port1
    input [AW-1:0] addr1,
    input [DW-1:0] din1,
    output reg [DW-1:0] dout1,
    input we1,
    // Port2
    input [AW-1:0] addr2,
    input [DW-1:0] din2,
    output reg [DW-1:0] dout2,
    input we2
);

reg [DW-1:0] mem [0:(1<<AW)-1];

// 流水线寄存器
reg [AW-1:0] addr1_stage1, addr2_stage1;
reg [DW-1:0] din1_stage1, din2_stage1;
reg we1_stage1, we2_stage1;
reg protect1_stage1, protect2_stage1;

reg [AW-1:0] addr1_stage2, addr2_stage2;
reg [DW-1:0] read_data1_stage2, read_data2_stage2;

// 条件求和减法器信号
wire [AW-1:0] addr1_diff_start, addr1_diff_end;
wire [AW-1:0] addr2_diff_start, addr2_diff_end;
wire addr1_in_range, addr2_in_range;

// 条件求和减法器实现
assign addr1_diff_start = addr1 - protect_start;
assign addr1_diff_end = protect_end - addr1;
assign addr2_diff_start = addr2 - protect_start;
assign addr2_diff_end = protect_end - addr2;

assign addr1_in_range = ~addr1_diff_start[AW-1] & ~addr1_diff_end[AW-1];
assign addr2_in_range = ~addr2_diff_start[AW-1] & ~addr2_diff_end[AW-1];

// 第一级流水线：计算保护区域判断和注册输入信号
always @(posedge clk) begin
    // 注册输入
    addr1_stage1 <= addr1;
    addr2_stage1 <= addr2;
    din1_stage1 <= din1;
    din2_stage1 <= din2;
    we1_stage1 <= we1;
    we2_stage1 <= we2;
    
    // 使用条件求和减法器结果
    protect1_stage1 <= addr1_in_range;
    protect2_stage1 <= addr2_in_range;
end

// 第二级流水线：处理内存访问
always @(posedge clk) begin
    // 注册地址用于下一级读取
    addr1_stage2 <= addr1_stage1;
    addr2_stage2 <= addr2_stage1;
    
    // 写入操作
    if (we1_stage1 && !protect1_stage1) 
        mem[addr1_stage1] <= din1_stage1;
    
    if (we2_stage1 && !protect2_stage1)
        mem[addr2_stage1] <= din2_stage1;
    
    // 读取操作
    read_data1_stage2 <= mem[addr1_stage1];
    read_data2_stage2 <= mem[addr2_stage1];
end

// 第三级流水线：输出读取结果
always @(posedge clk) begin
    dout1 <= read_data1_stage2;
    dout2 <= read_data2_stage2;
end

endmodule