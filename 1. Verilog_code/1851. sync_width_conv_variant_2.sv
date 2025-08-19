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
reg [CNT_W:0] wr_ptr_next, rd_ptr_next;
reg [IN_W-1:0] buffer_wr_data;
reg [OUT_W-1:0] dout_next;

// 添加查找表辅助减法器实现
reg [CNT_W:0] diff;
reg [7:0] lut_sub [0:255][0:255]; // 查找表用于8位减法
reg is_full, is_empty;

// 初始化查找表
integer i, j;
initial begin
    for (i = 0; i < 256; i = i + 1) begin
        for (j = 0; j < 256; j = j + 1) begin
            lut_sub[i][j] = i - j;
        end
    end
end

// Pipeline stage 1: Calculate next pointers and write data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr_next <= 0;
        rd_ptr_next <= 0;
        buffer_wr_data <= 0;
    end else begin
        wr_ptr_next <= wr_ptr;
        rd_ptr_next <= rd_ptr;
        buffer_wr_data <= din;
    end
end

// Pipeline stage 2: Update pointers and write buffer
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) wr_ptr <= 0;
    else if (wr_en && !full) begin
        buffer[wr_ptr_next[CNT_W-1:0]] <= buffer_wr_data;
        wr_ptr <= wr_ptr_next + 1;
    end
end

// Pipeline stage 3: Read and output data
always @(posedge clk) begin
    if (rd_en && !empty) begin
        dout_next <= {buffer[rd_ptr_next[CNT_W-1:0]+1], buffer[rd_ptr_next[CNT_W-1:0]]};
        rd_ptr <= rd_ptr_next + 2;
    end
end

// Pipeline stage 4: Register output
always @(posedge clk) begin
    dout <= dout_next;
end

// 使用查找表实现减法逻辑，计算full和empty状态
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        diff <= 0;
        is_full <= 0;
        is_empty <= 1;
    end else begin
        if (wr_ptr[CNT_W-1:0] < 16 && rd_ptr[CNT_W-1:0] < 16) begin
            diff <= lut_sub[wr_ptr[CNT_W-1:0]][rd_ptr[CNT_W-1:0]];
        end else begin
            // 对于超出查找表范围的情况使用常规减法
            diff <= wr_ptr - rd_ptr;
        end
        
        is_full <= (diff >= DEPTH);
        is_empty <= (diff == 0);
    end
end

assign full = is_full;
assign empty = is_empty;
endmodule