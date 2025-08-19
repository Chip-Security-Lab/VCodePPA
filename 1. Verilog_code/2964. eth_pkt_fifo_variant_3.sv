//SystemVerilog
module eth_pkt_fifo #(
    parameter ADDR_WIDTH = 12,
    parameter PKT_MODE = 0  // 0: Cut-through, 1: Store-and-forward
)(
    input clk,
    input rst,
    input [63:0] wr_data,
    input wr_en,
    input wr_eop,
    output full,
    output [63:0] rd_data,
    input rd_en,
    output empty,
    output [ADDR_WIDTH-1:0] pkt_count
);
    localparam DEPTH = 2**ADDR_WIDTH;
    reg [63:0] mem [0:DEPTH-1];
    
    // 主指针寄存器
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] pkt_wr_ptr, pkt_rd_ptr;
    
    // 缓冲寄存器 - 为高扇出信号添加
    reg [ADDR_WIDTH:0] wr_ptr_buf1, wr_ptr_buf2;
    reg [ADDR_WIDTH:0] rd_ptr_buf1, rd_ptr_buf2;
    reg [ADDR_WIDTH:0] pkt_wr_ptr_buf1, pkt_wr_ptr_buf2;
    reg [ADDR_WIDTH:0] pkt_rd_ptr_buf1, pkt_rd_ptr_buf2;
    
    // 初始化存储器和指针
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 64'h0;
        end
        wr_ptr = {(ADDR_WIDTH+1){1'b0}};
        rd_ptr = {(ADDR_WIDTH+1){1'b0}};
        pkt_wr_ptr = {(ADDR_WIDTH+1){1'b0}};
        pkt_rd_ptr = {(ADDR_WIDTH+1){1'b0}};
        
        // 缓冲寄存器初始化
        wr_ptr_buf1 = {(ADDR_WIDTH+1){1'b0}};
        wr_ptr_buf2 = {(ADDR_WIDTH+1){1'b0}};
        rd_ptr_buf1 = {(ADDR_WIDTH+1){1'b0}};
        rd_ptr_buf2 = {(ADDR_WIDTH+1){1'b0}};
        pkt_wr_ptr_buf1 = {(ADDR_WIDTH+1){1'b0}};
        pkt_wr_ptr_buf2 = {(ADDR_WIDTH+1){1'b0}};
        pkt_rd_ptr_buf1 = {(ADDR_WIDTH+1){1'b0}};
        pkt_rd_ptr_buf2 = {(ADDR_WIDTH+1){1'b0}};
    end

    // 缓冲寄存器更新 - 分散负载
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr_buf1 <= 0;
            wr_ptr_buf2 <= 0;
            rd_ptr_buf1 <= 0;
            rd_ptr_buf2 <= 0;
            pkt_wr_ptr_buf1 <= 0;
            pkt_wr_ptr_buf2 <= 0;
            pkt_rd_ptr_buf1 <= 0;
            pkt_rd_ptr_buf2 <= 0;
        end else begin
            wr_ptr_buf1 <= wr_ptr;
            wr_ptr_buf2 <= wr_ptr_buf1;
            rd_ptr_buf1 <= rd_ptr;
            rd_ptr_buf2 <= rd_ptr_buf1;
            pkt_wr_ptr_buf1 <= pkt_wr_ptr;
            pkt_wr_ptr_buf2 <= pkt_wr_ptr_buf1;
            pkt_rd_ptr_buf1 <= pkt_rd_ptr;
            pkt_rd_ptr_buf2 <= pkt_rd_ptr_buf1;
        end
    end
    
    // FIFO状态信号 - 使用优化后的缓冲路径
    assign full = (wr_ptr_buf1[ADDR_WIDTH-1:0] == rd_ptr_buf1[ADDR_WIDTH-1:0]) && 
                 (wr_ptr_buf1[ADDR_WIDTH] != rd_ptr_buf1[ADDR_WIDTH]);
    assign empty = (wr_ptr_buf2 == rd_ptr_buf2);
    assign pkt_count = pkt_wr_ptr_buf1 - pkt_rd_ptr_buf1;

    // 写入逻辑
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            pkt_wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            if (wr_eop) pkt_wr_ptr <= pkt_wr_ptr + 1;
        end
    end
    
    // 读取逻辑
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            pkt_rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            if (mem[rd_ptr[ADDR_WIDTH-1:0]][63:56] == 8'hFD) 
                pkt_rd_ptr <= pkt_rd_ptr + 1;
        end
    end
    
    // 存储器访问缓冲
    reg [63:0] mem_rd_data;
    always @(posedge clk) begin
        mem_rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
    end
    
    // 输出逻辑
    reg [63:0] pkt_buffer [0:3];
    reg [63:0] fifo_data;
    
    // 读取指针缓冲 - 针对Store-and-forward模式
    reg [1:0] rd_ptr_lower_bits;
    always @(posedge clk) begin
        rd_ptr_lower_bits <= rd_ptr[1:0];
    end
    
    // 根据模式选择输出数据
    always @(posedge clk) begin
        if (rst) begin
            fifo_data <= 64'h0;
            for (i = 0; i < 4; i = i + 1) begin
                pkt_buffer[i] <= 64'h0;
            end
        end else begin
            if (PKT_MODE == 0) begin
                // Cut-through 模式 - 使用缓冲的存储器访问
                fifo_data <= mem_rd_data;
            end else begin
                // Store-and-forward 模式
                if (pkt_rd_ptr_buf2 != pkt_wr_ptr_buf2) begin
                    // 使用缓冲的指针访问内存，分散负载
                    pkt_buffer[0] <= mem[{pkt_rd_ptr_buf2[ADDR_WIDTH-3:0], 2'b00}];
                    pkt_buffer[1] <= mem[{pkt_rd_ptr_buf2[ADDR_WIDTH-3:0], 2'b01}];
                    pkt_buffer[2] <= mem[{pkt_rd_ptr_buf2[ADDR_WIDTH-3:0], 2'b10}];
                    pkt_buffer[3] <= mem[{pkt_rd_ptr_buf2[ADDR_WIDTH-3:0], 2'b11}];
                    
                    fifo_data <= pkt_buffer[rd_ptr_lower_bits];
                end
            end
        end
    end
    
    assign rd_data = fifo_data;
endmodule