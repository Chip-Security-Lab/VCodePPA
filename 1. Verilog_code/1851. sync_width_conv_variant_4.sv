//SystemVerilog
module sync_width_conv #(parameter IN_W=8, OUT_W=16, DEPTH=4) (
    input clk, rst_n,
    input [IN_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output reg [OUT_W-1:0] dout
);
localparam CNT_W = $clog2(DEPTH);
reg [IN_W-1:0] buffer[0:DEPTH-1];
reg [CNT_W:0] wr_ptr = 0, rd_ptr = 0;
reg [IN_W-1:0] din_reg;
reg wr_en_reg, rd_en_reg;
wire full_pre, empty_pre;
reg [CNT_W-1:0] rd_addr_next;

// 前向寄存器重定时：将输入信号先寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_reg <= 0;
        wr_en_reg <= 0;
        rd_en_reg <= 0;
    end else begin
        din_reg <= din;
        wr_en_reg <= wr_en;
        rd_en_reg <= rd_en;
    end
end

// 移动后的写逻辑，使用寄存后的输入信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) wr_ptr <= 0;
    else if (wr_en_reg && !full_pre) begin
        buffer[wr_ptr[CNT_W-1:0]] <= din_reg;
        wr_ptr <= wr_ptr + 1;
    end
end

// 计算下一个读地址
always @(*) begin
    rd_addr_next = rd_ptr[CNT_W-1:0];
end

// 读逻辑优化
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr <= 0;
        dout <= 0;
    end else if (rd_en_reg && !empty_pre) begin
        dout <= {buffer[rd_ptr[CNT_W-1:0]+1], buffer[rd_ptr[CNT_W-1:0]]};
        rd_ptr <= rd_ptr + 2;
    end
end

// 使用寄存前的信号生成预测状态
assign full_pre = (wr_ptr - rd_ptr) >= (DEPTH-1);
assign empty_pre = (wr_ptr == rd_ptr);

// 实际输出状态
assign full = (wr_ptr - rd_ptr) >= DEPTH;
assign empty = (wr_ptr == rd_ptr);

endmodule