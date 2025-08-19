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
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] pkt_wr_ptr, pkt_rd_ptr;
    wire wr_pkt_end;
    
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
    end

    assign full = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && 
                 (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]);
    assign empty = (wr_ptr == rd_ptr);
    
    // 使用Kogge-Stone加法器计算pkt_count
    wire [ADDR_WIDTH-1:0] pkt_count_result;
    kogge_stone_adder #(
        .WIDTH(ADDR_WIDTH)
    ) pkt_counter (
        .a(pkt_wr_ptr[ADDR_WIDTH-1:0]),
        .b(~pkt_rd_ptr[ADDR_WIDTH-1:0]),
        .cin(1'b1),
        .sum(pkt_count_result),
        .cout()
    );
    assign pkt_count = pkt_count_result;

    // 写入逻辑
    wire [ADDR_WIDTH:0] wr_ptr_next;
    wire [ADDR_WIDTH:0] pkt_wr_ptr_next;
    
    kogge_stone_adder #(
        .WIDTH(ADDR_WIDTH+1)
    ) wr_ptr_adder (
        .a(wr_ptr),
        .b({{ADDR_WIDTH{1'b0}}, 1'b1}),
        .cin(1'b0),
        .sum(wr_ptr_next),
        .cout()
    );
    
    kogge_stone_adder #(
        .WIDTH(ADDR_WIDTH+1)
    ) pkt_wr_ptr_adder (
        .a(pkt_wr_ptr),
        .b({{ADDR_WIDTH{1'b0}}, 1'b1}),
        .cin(1'b0),
        .sum(pkt_wr_ptr_next),
        .cout()
    );
    
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            pkt_wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr_next;
            if (wr_eop) pkt_wr_ptr <= pkt_wr_ptr_next;
        end
    end
    
    // 读取逻辑
    wire [ADDR_WIDTH:0] rd_ptr_next;
    wire [ADDR_WIDTH:0] pkt_rd_ptr_next;
    
    kogge_stone_adder #(
        .WIDTH(ADDR_WIDTH+1)
    ) rd_ptr_adder (
        .a(rd_ptr),
        .b({{ADDR_WIDTH{1'b0}}, 1'b1}),
        .cin(1'b0),
        .sum(rd_ptr_next),
        .cout()
    );
    
    kogge_stone_adder #(
        .WIDTH(ADDR_WIDTH+1)
    ) pkt_rd_ptr_adder (
        .a(pkt_rd_ptr),
        .b({{ADDR_WIDTH{1'b0}}, 1'b1}),
        .cin(1'b0),
        .sum(pkt_rd_ptr_next),
        .cout()
    );
    
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            pkt_rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr_next;
            if (mem[rd_ptr[ADDR_WIDTH-1:0]][63:56] == 8'hFD) 
                pkt_rd_ptr <= pkt_rd_ptr_next;
        end
    end
    
    // 输出逻辑
    reg [63:0] pkt_buffer [0:3];
    reg [63:0] fifo_data;
    
    // 根据模式选择输出数据
    always @(posedge clk) begin
        if (rst) begin
            fifo_data <= 64'h0;
            for (i = 0; i < 4; i = i + 1) begin
                pkt_buffer[i] <= 64'h0;
            end
        end else begin
            if (PKT_MODE == 0) begin
                // Cut-through 模式
                fifo_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            end else begin
                // Store-and-forward 模式
                if (pkt_rd_ptr != pkt_wr_ptr) begin
                    pkt_buffer[0] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b00}];
                    pkt_buffer[1] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b01}];
                    pkt_buffer[2] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b10}];
                    pkt_buffer[3] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b11}];
                    
                    fifo_data <= pkt_buffer[rd_ptr[1:0]];
                end
            end
        end
    end
    
    assign rd_data = fifo_data;
endmodule

module kogge_stone_adder #(
    parameter WIDTH = 64
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 定义生成和传播信号
    wire [WIDTH-1:0] p_init; // 初始传播信号
    wire [WIDTH-1:0] g_init; // 初始生成信号
    
    // 各级传播和生成信号
    wire [WIDTH-1:0] p_lvl [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] g_lvl [0:$clog2(WIDTH)];
    
    // 计算初始传播和生成信号
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_init
            assign p_init[i] = a[i] ^ b[i];
            assign g_init[i] = a[i] & b[i];
        end
    endgenerate
    
    // 第0级为初始信号
    assign p_lvl[0] = p_init;
    assign g_lvl[0] = g_init;
    
    // Kogge-Stone并行前缀结构 - 计算所有级别的G和P
    generate
        genvar lvl, j;
        for (lvl = 0; lvl < $clog2(WIDTH); lvl = lvl + 1) begin: prefix_level
            for (j = 0; j < WIDTH; j = j + 1) begin: prefix_bit
                if (j >= (1 << lvl)) begin
                    // 该位需要前lvl级的合并
                    assign g_lvl[lvl+1][j] = g_lvl[lvl][j] | (p_lvl[lvl][j] & g_lvl[lvl][j-(1<<lvl)]);
                    assign p_lvl[lvl+1][j] = p_lvl[lvl][j] & p_lvl[lvl][j-(1<<lvl)];
                end else begin
                    // 该位不需要合并，直接传递
                    assign g_lvl[lvl+1][j] = g_lvl[lvl][j];
                    assign p_lvl[lvl+1][j] = p_lvl[lvl][j];
                end
            end
        end
    endgenerate
    
    // 计算进位信号
    wire [WIDTH:0] carry;
    assign carry[0] = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            // 计算每一位的进位
            if (i == 0) begin
                assign carry[i+1] = g_lvl[$clog2(WIDTH)][i] | (p_lvl[$clog2(WIDTH)][i] & cin);
            end else begin
                assign carry[i+1] = g_lvl[$clog2(WIDTH)][i];
            end
        end
    endgenerate
    
    // 计算最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p_init[i] ^ carry[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = carry[WIDTH];
endmodule