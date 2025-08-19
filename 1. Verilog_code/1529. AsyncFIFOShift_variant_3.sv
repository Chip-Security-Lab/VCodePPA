//SystemVerilog
// IEEE 1364-2005 Verilog
module AsyncFIFOShift #(parameter DEPTH=8, AW=$clog2(DEPTH)) (
    input wr_clk, rd_clk,
    input wr_en, rd_en,
    input din,
    output dout,
    // 新增流水线控制信号
    input rst_n,
    output reg fifo_empty,
    output reg fifo_full,
    output reg valid_out
);
    // 存储单元
    reg [DEPTH-1:0] mem = 0;
    
    // 指针和计数器
    reg [AW:0] wr_ptr_stage1 = 0;
    reg [AW:0] rd_ptr_stage1 = 0;
    reg [AW:0] wr_ptr_gray_stage1 = 0;
    reg [AW:0] rd_ptr_gray_stage1 = 0;
    
    // 同步寄存器 - 增加同步深度
    reg [AW:0] wr_ptr_gray_sync1 = 0;
    reg [AW:0] wr_ptr_gray_sync2 = 0;
    reg [AW:0] wr_ptr_gray_sync3 = 0;
    reg [AW:0] rd_ptr_gray_sync1 = 0;
    reg [AW:0] rd_ptr_gray_sync2 = 0;
    reg [AW:0] rd_ptr_gray_sync3 = 0;
    
    // 增强的流水线状态寄存器
    reg [AW:0] wr_ptr_binary_stage2 = 0;
    reg [AW:0] wr_ptr_binary_stage3 = 0;
    reg [AW:0] rd_ptr_binary_stage2 = 0;
    reg [AW:0] rd_ptr_binary_stage3 = 0;
    
    // 写流水线寄存器
    reg wr_valid_stage1 = 0, wr_valid_stage2 = 0, wr_valid_stage3 = 0;
    reg din_stage1 = 0, din_stage2 = 0;
    reg [AW-1:0] wr_addr_stage1 = 0, wr_addr_stage2 = 0;
    
    // 读流水线寄存器
    reg rd_valid_stage1 = 0, rd_valid_stage2 = 0, rd_valid_stage3 = 0, rd_valid_stage4 = 0;
    reg [AW-1:0] rd_addr_stage1 = 0, rd_addr_stage2 = 0, rd_addr_stage3 = 0;
    reg dout_stage1 = 0, dout_stage2 = 0, dout_stage3 = 0;
    
    // 二进制码转格雷码函数
    function [AW:0] bin2gray(input [AW:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction
    
    // 格雷码转二进制码函数 - 优化分级计算
    function [AW:0] gray2bin(input [AW:0] gray);
        integer i;
        reg [AW:0] bin;
        bin = gray;
        for (i = 1; i <= AW; i = i + 1)
            bin = bin ^ (gray >> i);
        gray2bin = bin;
    endfunction
    
    // 写入流水线 - 阶段1：计算和验证
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_valid_stage1 <= 0;
            wr_addr_stage1 <= 0;
        end else begin
            wr_valid_stage1 <= wr_en && !fifo_full;
            wr_addr_stage1 <= wr_ptr_stage1[AW-1:0];
        end
    end
    
    // 写入流水线 - 阶段2：地址计算和数据捕获
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 0;
            wr_valid_stage2 <= 0;
            din_stage1 <= 0;
            wr_ptr_gray_stage1 <= 0;
            wr_addr_stage2 <= 0;
        end else begin
            wr_valid_stage2 <= wr_valid_stage1;
            wr_addr_stage2 <= wr_addr_stage1;
            
            if (wr_valid_stage1) begin
                din_stage1 <= din;
                wr_ptr_stage1 <= wr_ptr_stage1 + 1;
                wr_ptr_gray_stage1 <= bin2gray(wr_ptr_stage1 + 1);
            end
        end
    end
    
    // 写入流水线 - 阶段3：数据准备
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_valid_stage3 <= 0;
            din_stage2 <= 0;
        end else begin
            wr_valid_stage3 <= wr_valid_stage2;
            if (wr_valid_stage2) begin
                din_stage2 <= din_stage1;
            end
        end
    end
    
    // 写入流水线 - 阶段4：数据写入存储
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= 0;
        end else begin
            if (wr_valid_stage3) begin
                mem[wr_addr_stage2] <= din_stage2;
            end
        end
    end
    
    // 读取流水线 - 阶段1：控制验证
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_valid_stage1 <= 0;
        end else begin
            rd_valid_stage1 <= rd_en && !fifo_empty;
        end
    end
    
    // 读取流水线 - 阶段2：地址计算
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_stage1 <= 0;
            rd_valid_stage2 <= 0;
            rd_addr_stage1 <= 0;
            rd_ptr_gray_stage1 <= 0;
        end else begin
            rd_valid_stage2 <= rd_valid_stage1;
            
            if (rd_valid_stage1) begin
                rd_addr_stage1 <= rd_ptr_stage1[AW-1:0];
                rd_ptr_stage1 <= rd_ptr_stage1 + 1;
                rd_ptr_gray_stage1 <= bin2gray(rd_ptr_stage1 + 1);
            end
        end
    end
    
    // 读取流水线 - 阶段3：数据读取准备
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_valid_stage3 <= 0;
            rd_addr_stage2 <= 0;
        end else begin
            rd_valid_stage3 <= rd_valid_stage2;
            rd_addr_stage2 <= rd_addr_stage1;
        end
    end
    
    // 读取流水线 - 阶段4：数据读取
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_valid_stage4 <= 0;
            rd_addr_stage3 <= 0;
            dout_stage1 <= 0;
        end else begin
            rd_valid_stage4 <= rd_valid_stage3;
            rd_addr_stage3 <= rd_addr_stage2;
            
            if (rd_valid_stage3) begin
                dout_stage1 <= mem[rd_addr_stage2];
            end
        end
    end
    
    // 读取流水线 - 阶段5：输出准备
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= rd_valid_stage4;
            
            if (rd_valid_stage4) begin
                dout_stage2 <= dout_stage1;
            end
        end
    end
    
    // 读取流水线 - 阶段6：最终输出
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage3 <= 0;
        end else begin
            if (valid_out) begin
                dout_stage3 <= dout_stage2;
            end
        end
    end
    
    // 跨时钟域同步 - 写指针同步到读时钟域（增加同步深度）
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
            wr_ptr_gray_sync3 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray_stage1;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
            wr_ptr_gray_sync3 <= wr_ptr_gray_sync2;
        end
    end
    
    // 跨时钟域同步 - 读指针同步到写时钟域（增加同步深度）
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
            rd_ptr_gray_sync3 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray_stage1;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
            rd_ptr_gray_sync3 <= rd_ptr_gray_sync2;
        end
    end
    
    // 同步指针转换为二进制 - 分两级计算
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_binary_stage2 <= 0;
            rd_ptr_binary_stage3 <= 0;
        end else begin
            // 拆分格雷码转二进制的计算过程为两级
            rd_ptr_binary_stage2 <= rd_ptr_gray_sync3;
            rd_ptr_binary_stage3 <= gray2bin(rd_ptr_gray_sync3);
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_binary_stage2 <= 0;
            wr_ptr_binary_stage3 <= 0;
        end else begin
            // 拆分格雷码转二进制的计算过程为两级
            wr_ptr_binary_stage2 <= wr_ptr_gray_sync3;
            wr_ptr_binary_stage3 <= gray2bin(wr_ptr_gray_sync3);
        end
    end
    
    // 满空状态计算 - 基于优化的同步指针
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_full <= 0;
        end else begin
            fifo_full <= (wr_ptr_stage1[AW-1:0] == rd_ptr_binary_stage3[AW-1:0]) && 
                         (wr_ptr_stage1[AW] != rd_ptr_binary_stage3[AW]);
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_empty <= 1;
        end else begin
            fifo_empty <= (rd_ptr_stage1 == wr_ptr_binary_stage3);
        end
    end
    
    // 输出数据
    assign dout = dout_stage3;
    
endmodule