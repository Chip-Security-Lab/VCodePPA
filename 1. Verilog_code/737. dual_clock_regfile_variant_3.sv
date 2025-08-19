//SystemVerilog
module dual_clock_regfile_pipeline #(
    parameter DW = 48,
    parameter AW = 5
)(
    input wr_clk,
    input rd_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data,
    output reg valid_rd,
    output reg valid_wr
);

reg [DW-1:0] mem [0:(1<<AW)-1];

// 写入流水线增强
reg wr_en_stage1, wr_en_stage2;
reg [AW-1:0] wr_addr_stage1, wr_addr_stage2;
reg [DW-1:0] wr_data_stage1, wr_data_stage2;
reg valid_wr_internal;

// 读取流水线增强
reg [AW-1:0] rd_addr_stage1, rd_addr_stage2;
reg [DW-1:0] sync_reg_stage1, sync_reg_stage2, sync_reg_stage3, sync_reg_stage4;
reg valid_rd_stage1, valid_rd_stage2, valid_rd_stage3, valid_rd_stage4;

// 写入流水线 - 第一级
always @(posedge wr_clk) begin
    wr_en_stage1 <= wr_en;
    wr_addr_stage1 <= wr_addr;
    wr_data_stage1 <= wr_data;
end

// 写入流水线 - 第二级
always @(posedge wr_clk) begin
    wr_en_stage2 <= wr_en_stage1;
    wr_addr_stage2 <= wr_addr_stage1;
    wr_data_stage2 <= wr_data_stage1;
    valid_wr_internal <= wr_en_stage1;
end

// 写入流水线 - 第三级(最终写入)
always @(posedge wr_clk) begin
    if (wr_en_stage2) begin
        mem[wr_addr_stage2] <= wr_data_stage2;
    end
    valid_wr <= valid_wr_internal;
end

// 读取流水线 - 地址寄存第一级
always @(posedge rd_clk) begin
    rd_addr_stage1 <= rd_addr;
    valid_rd_stage1 <= 1'b1;
end

// 读取流水线 - 地址寄存第二级
always @(posedge rd_clk) begin
    rd_addr_stage2 <= rd_addr_stage1;
    valid_rd_stage2 <= valid_rd_stage1;
end

// 读取流水线 - 数据获取阶段
always @(posedge rd_clk) begin
    sync_reg_stage1 <= mem[rd_addr_stage2];
    valid_rd_stage3 <= valid_rd_stage2;
end

// 读取流水线 - 数据同步第一级
always @(posedge rd_clk) begin
    sync_reg_stage2 <= sync_reg_stage1;
    valid_rd_stage4 <= valid_rd_stage3;
end

// 读取流水线 - 数据同步第二级
always @(posedge rd_clk) begin
    sync_reg_stage3 <= sync_reg_stage2;
    valid_rd <= valid_rd_stage4;
end

// 读取流水线 - 数据同步第三级
always @(posedge rd_clk) begin
    sync_reg_stage4 <= sync_reg_stage3;
end

// 输出级
always @(posedge rd_clk) begin
    rd_data <= sync_reg_stage4;
end

endmodule