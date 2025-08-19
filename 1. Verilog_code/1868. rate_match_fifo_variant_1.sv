//SystemVerilog
module rate_match_fifo #(parameter DATA_W=8, DEPTH=8) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input wr_en, rd_en,
    output reg full, empty,
    output reg [DATA_W-1:0] dout
);
    // 存储器定义
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    
    // 写入部分流水线寄存器
    reg [$clog2(DEPTH):0] wr_ptr_stage1 = 0;
    reg [$clog2(DEPTH):0] wr_ptr_stage2 = 0;
    reg wr_valid_stage1 = 0;
    reg [DATA_W-1:0] din_stage1 = 0;
    
    // 读取部分流水线寄存器
    reg [$clog2(DEPTH):0] rd_ptr_stage1 = 0;
    reg [$clog2(DEPTH):0] rd_ptr_stage2 = 0;
    reg rd_valid_stage1 = 0;
    reg [DATA_W-1:0] dout_stage1 = 0;
    
    // 跨时钟域同步寄存器
    reg [$clog2(DEPTH):0] rd_ptr_sync1 = 0, rd_ptr_sync2 = 0;
    reg [$clog2(DEPTH):0] wr_ptr_sync1 = 0, wr_ptr_sync2 = 0;
    
    // 写入流水线第一级 - 检查条件和准备数据
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_valid_stage1 <= 0;
            din_stage1 <= 0;
            wr_ptr_stage1 <= 0;
        end else begin
            wr_valid_stage1 <= wr_en && !full;
            din_stage1 <= din;
            wr_ptr_stage1 <= wr_ptr_stage2;
        end
    end
    
    // 写入流水线第二级 - 执行写入操作
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_stage2 <= 0;
        end else if (wr_valid_stage1) begin
            mem[wr_ptr_stage1[$clog2(DEPTH)-1:0]] <= din_stage1;
            wr_ptr_stage2 <= wr_ptr_stage1 + 1;
        end
    end
    
    // 读取流水线第一级 - 检查条件和准备地址
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_valid_stage1 <= 0;
            rd_ptr_stage1 <= 0;
        end else begin
            rd_valid_stage1 <= rd_en && !empty;
            rd_ptr_stage1 <= rd_ptr_stage2;
        end
    end
    
    // 读取流水线第二级 - 执行读取操作
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_stage2 <= 0;
            dout_stage1 <= 0;
            dout <= 0;
        end else begin
            if (rd_valid_stage1) begin
                dout_stage1 <= mem[rd_ptr_stage1[$clog2(DEPTH)-1:0]];
                rd_ptr_stage2 <= rd_ptr_stage1 + 1;
            end
            dout <= dout_stage1; // 输出流水线
        end
    end
    
    // 跨时钟域同步
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_sync1 <= 0;
            rd_ptr_sync2 <= 0;
        end else begin
            rd_ptr_sync1 <= rd_ptr_stage2;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end
    
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_sync1 <= 0;
            wr_ptr_sync2 <= 0;
        end else begin
            wr_ptr_sync1 <= wr_ptr_stage2;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end
    
    // 状态标志计算 - 流水线化
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            full <= 0;
        else
            full <= ((wr_ptr_stage2 - rd_ptr_sync2) >= DEPTH-1);
    end
    
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            empty <= 1;
        else
            empty <= (wr_ptr_sync2 == rd_ptr_stage2);
    end
    
endmodule