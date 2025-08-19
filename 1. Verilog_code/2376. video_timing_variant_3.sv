//SystemVerilog
module video_timing #(parameter H_TOTAL=800)(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    output reg h_sync,
    output wire [9:0] h_count,
    output reg valid_out  // 添加有效输出信号
);

// 流水线阶段1: 计数器逻辑
reg [9:0] cnt_stage1;
reg valid_stage1;

// 流水线阶段2: 存储中间状态
reg [9:0] cnt_stage2;
reg valid_stage2;

// 输出赋值
assign h_count = cnt_stage2;

// Kogge-Stone加法器内部信号
wire [9:0] p, g;
wire [9:0] pp1, gg1;
wire [9:0] pp2, gg2;
wire [9:0] pp3, gg3;
wire [9:0] pp4, gg4;
wire [9:0] sum;
wire [10:0] carry;

// 预处理：生成初始传播和生成信号
assign p = cnt_stage2 ^ {10{1'b1}}; // p = a XOR b (b全1表示+1)
assign g = cnt_stage2 & {10{1'b1}}; // g = a AND b (b全1表示+1)
assign carry[0] = 1'b1; // 进位输入为1

// 第一级树
assign pp1[0] = p[0];
assign gg1[0] = g[0];
assign pp1[9:1] = p[9:1] & p[8:0];
assign gg1[9:1] = g[9:1] | (p[9:1] & g[8:0]);

// 第二级树
assign pp2[0] = pp1[0];
assign pp2[1] = pp1[1];
assign gg2[0] = gg1[0];
assign gg2[1] = gg1[1];
assign pp2[9:2] = pp1[9:2] & pp1[7:0];
assign gg2[9:2] = gg1[9:2] | (pp1[9:2] & gg1[7:0]);

// 第三级树
assign pp3[0] = pp2[0];
assign pp3[1] = pp2[1];
assign pp3[2] = pp2[2];
assign pp3[3] = pp2[3];
assign gg3[0] = gg2[0];
assign gg3[1] = gg2[1];
assign gg3[2] = gg2[2];
assign gg3[3] = gg2[3];
assign pp3[9:4] = pp2[9:4] & pp2[5:0];
assign gg3[9:4] = gg2[9:4] | (pp2[9:4] & gg2[5:0]);

// 第四级树
assign pp4 = pp3;
assign gg4[0] = gg3[0];
assign gg4[9:1] = gg3[9:1] | (pp3[9:1] & gg3[8:0]);

// 计算进位
assign carry[1] = gg4[0] | (pp4[0] & carry[0]);
assign carry[2] = gg4[1] | (pp4[1] & carry[1]);
assign carry[3] = gg4[2] | (pp4[2] & carry[2]);
assign carry[4] = gg4[3] | (pp4[3] & carry[3]);
assign carry[5] = gg4[4] | (pp4[4] & carry[4]);
assign carry[6] = gg4[5] | (pp4[5] & carry[5]);
assign carry[7] = gg4[6] | (pp4[6] & carry[6]);
assign carry[8] = gg4[7] | (pp4[7] & carry[7]);
assign carry[9] = gg4[8] | (pp4[8] & carry[8]);
assign carry[10] = gg4[9] | (pp4[9] & carry[9]);

// 求和
assign sum = p ^ carry[9:0];

// 流水线阶段1：计数逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_stage1 <= 10'd0;
        valid_stage1 <= 1'b0;
    end else begin
        cnt_stage1 <= (cnt_stage2 < H_TOTAL-1) ? sum : 10'd0;
        valid_stage1 <= 1'b1;  // 启动后一直有效
    end
end

// 流水线阶段2：结果寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_stage2 <= 10'd0;
        valid_stage2 <= 1'b0;
    end else begin
        cnt_stage2 <= cnt_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// 输出阶段：根据计数值生成同步信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_sync <= 1'b1;
        valid_out <= 1'b0;
    end else begin
        h_sync <= (cnt_stage2 < 96) ? 1'b0 : 1'b1;
        valid_out <= valid_stage2;
    end
end

endmodule