//SystemVerilog
// IEEE 1364-2005 Verilog标准
module AsyncFIFOShift #(
    parameter DEPTH = 8,
    parameter AW    = $clog2(DEPTH)
) (
    input  wire       wr_clk,
    input  wire       rd_clk,
    input  wire       resetn,     // 添加异步复位信号
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire       din,
    output wire       dout,
    output wire       full,       // 添加满信号
    output wire       empty       // 添加空信号
);

    // 内存和指针寄存器
    reg [DEPTH-1:0] mem;
    
    // 写时钟域信号
    reg [AW:0]      wr_ptr_stage1;
    reg [AW:0]      wr_ptr_stage2;
    reg             wr_valid_stage1;
    reg             wr_valid_stage2;
    reg             din_stage1;
    
    // 读时钟域信号
    reg [AW:0]      rd_ptr_stage1;
    reg [AW:0]      rd_ptr_stage2;
    reg             rd_valid_stage1;
    reg             rd_valid_stage2;
    reg             dout_stage1;
    reg             dout_stage2;
    
    // 时钟域转换寄存器 (格雷码转换用于跨时钟域)
    reg [AW:0]      wr_ptr_gray;
    reg [AW:0]      rd_ptr_gray;
    reg [AW:0]      wr_ptr_gray_sync1;
    reg [AW:0]      wr_ptr_gray_sync2;
    reg [AW:0]      rd_ptr_gray_sync1;
    reg [AW:0]      rd_ptr_gray_sync2;
    
    // 二进制转格雷码
    function [AW:0] bin2gray(input [AW:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction
    
    // 格雷码转二进制
    function [AW:0] gray2bin(input [AW:0] gray);
        integer i;
        reg [AW:0] bin;
        begin
            bin = gray;
            for (i = 1; i <= AW; i = i + 1)
                bin = bin ^ (gray >> i);
            gray2bin = bin;
        end
    endfunction

    // 写流水线阶段1 - 地址计算与格雷码转换
    always @(posedge wr_clk or negedge resetn) begin
        if (!resetn) begin
            wr_ptr_stage1 <= {(AW+1){1'b0}};
            wr_valid_stage1 <= 1'b0;
            din_stage1 <= 1'b0;
        end else begin
            wr_valid_stage1 <= wr_en && !full;
            if (wr_en && !full) begin
                wr_ptr_stage1 <= wr_ptr_stage2 + 1'b1;
                din_stage1 <= din;
            end else begin
                wr_ptr_stage1 <= wr_ptr_stage2;
            end
        end
    end
    
    // 写流水线阶段2 - 内存写入
    always @(posedge wr_clk or negedge resetn) begin
        if (!resetn) begin
            wr_ptr_stage2 <= {(AW+1){1'b0}};
            wr_valid_stage2 <= 1'b0;
            wr_ptr_gray <= {(AW+1){1'b0}};
            mem <= {DEPTH{1'b0}};
        end else begin
            wr_valid_stage2 <= wr_valid_stage1;
            if (wr_valid_stage1) begin
                mem[wr_ptr_stage1[AW-1:0]] <= din_stage1;
                wr_ptr_stage2 <= wr_ptr_stage1;
                wr_ptr_gray <= bin2gray(wr_ptr_stage1);
            end
        end
    end
    
    // 读流水线阶段1 - 地址计算与数据读取
    always @(posedge rd_clk or negedge resetn) begin
        if (!resetn) begin
            rd_ptr_stage1 <= {(AW+1){1'b0}};
            rd_valid_stage1 <= 1'b0;
            dout_stage1 <= 1'b0;
        end else begin
            rd_valid_stage1 <= rd_en && !empty;
            if (rd_en && !empty) begin
                rd_ptr_stage1 <= rd_ptr_stage2 + 1'b1;
                dout_stage1 <= mem[rd_ptr_stage2[AW-1:0]];
            end else begin
                rd_ptr_stage1 <= rd_ptr_stage2;
            end
        end
    end
    
    // 读流水线阶段2 - 输出处理
    always @(posedge rd_clk or negedge resetn) begin
        if (!resetn) begin
            rd_ptr_stage2 <= {(AW+1){1'b0}};
            rd_valid_stage2 <= 1'b0;
            rd_ptr_gray <= {(AW+1){1'b0}};
            dout_stage2 <= 1'b0;
        end else begin
            rd_valid_stage2 <= rd_valid_stage1;
            if (rd_valid_stage1) begin
                rd_ptr_stage2 <= rd_ptr_stage1;
                rd_ptr_gray <= bin2gray(rd_ptr_stage1);
                dout_stage2 <= dout_stage1;
            end
        end
    end
    
    // 时钟域同步
    always @(posedge wr_clk or negedge resetn) begin
        if (!resetn) begin
            rd_ptr_gray_sync1 <= {(AW+1){1'b0}};
            rd_ptr_gray_sync2 <= {(AW+1){1'b0}};
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    always @(posedge rd_clk or negedge resetn) begin
        if (!resetn) begin
            wr_ptr_gray_sync1 <= {(AW+1){1'b0}};
            wr_ptr_gray_sync2 <= {(AW+1){1'b0}};
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // 满空状态计算
    wire [AW:0] wr_ptr_binary = wr_ptr_stage2;
    wire [AW:0] rd_ptr_binary = rd_ptr_stage2;
    wire [AW:0] rd_ptr_sync = gray2bin(rd_ptr_gray_sync2);
    wire [AW:0] wr_ptr_sync = gray2bin(wr_ptr_gray_sync2);
    
    assign full = (wr_ptr_binary[AW] != rd_ptr_sync[AW]) && 
                  (wr_ptr_binary[AW-1:0] == rd_ptr_sync[AW-1:0]);
    assign empty = (rd_ptr_binary == wr_ptr_sync);
    
    // 输出赋值
    assign dout = dout_stage2;

endmodule