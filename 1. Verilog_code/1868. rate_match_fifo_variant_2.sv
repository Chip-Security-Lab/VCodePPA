//SystemVerilog
module rate_match_fifo #(parameter DATA_W=8, DEPTH=8) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output [DATA_W-1:0] dout
);

// 内存存储
reg [DATA_W-1:0] mem [0:DEPTH-1];

// 写路径流水线寄存器
reg [$clog2(DEPTH):0] wr_ptr_stage1 = 0;
reg [$clog2(DEPTH):0] wr_ptr_stage2 = 0;
reg [DATA_W-1:0] din_stage1, din_stage2;
reg wr_en_stage1, wr_en_stage2;
reg full_stage1, full_stage2, full_stage3;

// 读路径流水线寄存器
reg [$clog2(DEPTH):0] rd_ptr_stage1 = 0;
reg [$clog2(DEPTH):0] rd_ptr_stage2 = 0; 
reg rd_en_stage1, rd_en_stage2;
reg empty_stage1, empty_stage2, empty_stage3;
reg [DATA_W-1:0] dout_stage1, dout_stage2;

// 指针同步寄存器组 (Gray编码转换从此处省略，简化设计)
reg [$clog2(DEPTH):0] wr_ptr_sync1, wr_ptr_sync2;
reg [$clog2(DEPTH):0] rd_ptr_sync1, rd_ptr_sync2;

// 写时钟域 - 第一级流水线
always @(posedge wr_clk or posedge rst) begin
    if (rst) begin
        din_stage1 <= 0;
        wr_en_stage1 <= 0;
        rd_ptr_sync1 <= 0;
    end else begin
        din_stage1 <= din;
        wr_en_stage1 <= wr_en;
        rd_ptr_sync1 <= rd_ptr_stage2; // 跨时钟域同步
    end
end

// 写时钟域 - 第二级流水线
always @(posedge wr_clk or posedge rst) begin
    if (rst) begin
        din_stage2 <= 0;
        wr_en_stage2 <= 0;
        rd_ptr_sync2 <= 0;
        full_stage1 <= 0;
    end else begin
        din_stage2 <= din_stage1;
        wr_en_stage2 <= wr_en_stage1;
        rd_ptr_sync2 <= rd_ptr_sync1;
        full_stage1 <= ((wr_ptr_stage1 - rd_ptr_sync2) >= (DEPTH-1));
    end
end

// 写指针更新 - 第三级流水线
always @(posedge wr_clk or posedge rst) begin
    if (rst) begin
        wr_ptr_stage1 <= 0;
        full_stage2 <= 0;
    end else begin
        full_stage2 <= full_stage1;
        
        if (wr_en_stage2 && !full_stage1) begin
            mem[wr_ptr_stage1[$clog2(DEPTH)-1:0]] <= din_stage2;
            wr_ptr_stage1 <= wr_ptr_stage1 + 1;
        end
    end
end

// 输出寄存器 - 写路径
always @(posedge wr_clk or posedge rst) begin
    if (rst)
        full_stage3 <= 0;
    else
        full_stage3 <= full_stage2;
end

// 读时钟域 - 第一级流水线
always @(posedge rd_clk or posedge rst) begin
    if (rst) begin
        rd_en_stage1 <= 0;
        wr_ptr_sync1 <= 0;
    end else begin
        rd_en_stage1 <= rd_en;
        wr_ptr_sync1 <= wr_ptr_stage1; // 跨时钟域同步
    end
end

// 读时钟域 - 第二级流水线
always @(posedge rd_clk or posedge rst) begin
    if (rst) begin
        rd_en_stage2 <= 0;
        wr_ptr_sync2 <= 0;
        empty_stage1 <= 1;
    end else begin
        rd_en_stage2 <= rd_en_stage1;
        wr_ptr_sync2 <= wr_ptr_sync1;
        empty_stage1 <= (wr_ptr_sync2 == rd_ptr_stage1);
    end
end

// 读指针更新 - 第三级流水线
always @(posedge rd_clk or posedge rst) begin
    if (rst) begin
        rd_ptr_stage1 <= 0;
        empty_stage2 <= 1;
    end else begin
        empty_stage2 <= empty_stage1;
        
        if (rd_en_stage2 && !empty_stage1) begin
            rd_ptr_stage1 <= rd_ptr_stage1 + 1;
        end
    end
end

// 数据读出 - 第四级流水线 
always @(posedge rd_clk) begin
    dout_stage1 <= mem[rd_ptr_stage1[$clog2(DEPTH)-1:0]];
end

// 输出寄存器 - 读路径
always @(posedge rd_clk or posedge rst) begin
    if (rst) begin
        dout_stage2 <= 0;
        empty_stage3 <= 1;
    end else begin
        dout_stage2 <= dout_stage1;
        empty_stage3 <= empty_stage2;
    end
end

// 输出信号分配
assign full = full_stage3;
assign empty = empty_stage3;
assign dout = dout_stage2;

endmodule