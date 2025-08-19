//SystemVerilog
module eth_pkt_fifo #(
    parameter ADDR_WIDTH = 12,
    parameter PKT_MODE = 0  // 0: Cut-through, 1: Store-and-forward
)(
    input wire clk,
    input wire rst,
    input wire [63:0] wr_data,
    input wire wr_en,
    input wire wr_eop,
    output wire full,
    output wire [63:0] rd_data,
    input wire rd_en,
    output wire empty,
    output wire [ADDR_WIDTH-1:0] pkt_count
);
    // 常量定义
    localparam DEPTH = 2**ADDR_WIDTH;
    localparam BUFFER_STAGES = 4;
    
    // 存储器和指针声明
    (* ram_style = "block" *) reg [63:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr_q, rd_ptr_q;
    reg [ADDR_WIDTH:0] pkt_wr_ptr_q, pkt_rd_ptr_q;
    
    // 状态信号声明
    wire fifo_full, fifo_empty;
    wire pkt_end_detected;
    
    // 数据路径缓冲声明
    reg [63:0] read_data_stage1;
    reg [63:0] read_data_stage2;
    reg [63:0] pkt_buffer [0:BUFFER_STAGES-1];
    
    // LUT控制信号
    reg [3:0] control_lut_idx;
    reg [3:0] buffer_select_lut_idx;
    wire update_wr_ptr, update_pkt_wr;
    wire update_rd_ptr, update_pkt_rd;
    wire [1:0] output_select;
    
    // 流控状态
    assign fifo_full = (wr_ptr_q[ADDR_WIDTH-1:0] == rd_ptr_q[ADDR_WIDTH-1:0]) && 
                      (wr_ptr_q[ADDR_WIDTH] != rd_ptr_q[ADDR_WIDTH]);
    assign fifo_empty = (wr_ptr_q == rd_ptr_q);
    
    // 外部接口连接
    assign full = fifo_full;
    assign empty = fifo_empty;
    assign pkt_count = pkt_wr_ptr_q - pkt_rd_ptr_q;
    
    // 包结束检测
    assign pkt_end_detected = (rd_en && !fifo_empty && 
                              (mem[rd_ptr_q[ADDR_WIDTH-1:0]][63:56] == 8'hFD));
    
    // 存储器初始化
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 64'h0;
        end
        wr_ptr_q = {(ADDR_WIDTH+1){1'b0}};
        rd_ptr_q = {(ADDR_WIDTH+1){1'b0}};
        pkt_wr_ptr_q = {(ADDR_WIDTH+1){1'b0}};
        pkt_rd_ptr_q = {(ADDR_WIDTH+1){1'b0}};
    end

    // ========== 控制逻辑查找表 ==========
    // 写入控制查找表索引生成
    always @(*) begin
        control_lut_idx = {rst, wr_en, fifo_full, wr_eop};
    end
    
    // 预计算的写入控制查找表
    assign update_wr_ptr = ~control_lut_idx[3] & control_lut_idx[2] & ~control_lut_idx[1];
    assign update_pkt_wr = ~control_lut_idx[3] & control_lut_idx[2] & ~control_lut_idx[1] & control_lut_idx[0];

    // 读取控制查找表索引生成
    wire [2:0] rd_control_idx;
    assign rd_control_idx = {rst, rd_en, fifo_empty};
    
    // 预计算的读取控制查找表
    assign update_rd_ptr = ~rd_control_idx[2] & rd_control_idx[1] & ~rd_control_idx[0];
    assign update_pkt_rd = ~rd_control_idx[2] & rd_control_idx[1] & ~rd_control_idx[0] & pkt_end_detected;

    // ========== 写入数据路径 ==========
    // 写入控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr_q <= 0;
            pkt_wr_ptr_q <= 0;
        end else begin
            // 基于查找表更新写指针
            if (update_wr_ptr) begin
                mem[wr_ptr_q[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr_q <= wr_ptr_q + 1'b1;
            end
            
            // 基于查找表更新包计数
            if (update_pkt_wr) begin
                pkt_wr_ptr_q <= pkt_wr_ptr_q + 1'b1;
            end
        end
    end
    
    // ========== 读取数据路径 ==========
    // 读取控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr_q <= 0;
            pkt_rd_ptr_q <= 0;
        end else begin
            // 基于查找表更新读指针
            if (update_rd_ptr) begin
                rd_ptr_q <= rd_ptr_q + 1'b1;
            end
            
            // 基于查找表更新包读取计数
            if (update_pkt_rd) begin
                pkt_rd_ptr_q <= pkt_rd_ptr_q + 1'b1;
            end
        end
    end
    
    // ========== 数据输出流水线 ==========
    // 第一级：内存读取和模式选择
    always @(posedge clk) begin
        if (rst) begin
            read_data_stage1 <= 64'h0;
        end else if (update_rd_ptr) begin
            read_data_stage1 <= mem[rd_ptr_q[ADDR_WIDTH-1:0]];
        end
    end
    
    // 第二级：Store-and-forward模式缓冲管理
    // 缓冲控制查找表索引
    wire pkt_available;
    assign pkt_available = (pkt_rd_ptr_q != pkt_wr_ptr_q);
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < BUFFER_STAGES; i = i + 1) begin
                pkt_buffer[i] <= 64'h0;
            end
        end else if (PKT_MODE == 1 && pkt_available) begin
            // 使用查找表加载缓冲区
            pkt_buffer[0] <= mem[{pkt_rd_ptr_q[ADDR_WIDTH-3:0], 2'b00}];
            pkt_buffer[1] <= mem[{pkt_rd_ptr_q[ADDR_WIDTH-3:0], 2'b01}];
            pkt_buffer[2] <= mem[{pkt_rd_ptr_q[ADDR_WIDTH-3:0], 2'b10}];
            pkt_buffer[3] <= mem[{pkt_rd_ptr_q[ADDR_WIDTH-3:0], 2'b11}];
        end
    end
    
    // 第三级：输出选择查找表
    always @(*) begin
        buffer_select_lut_idx = {rst, PKT_MODE, rd_ptr_q[1:0]};
    end
    
    // 查找表输出选择
    assign output_select = (buffer_select_lut_idx[3]) ? 2'b00 : 
                          ((buffer_select_lut_idx[2]) ? 2'b01 : 2'b00);
    
    // 第三级：模式选择和最终输出
    always @(posedge clk) begin
        if (rst) begin
            read_data_stage2 <= 64'h0;
        end else begin
            case (output_select)
                2'b00: read_data_stage2 <= read_data_stage1;                // Cut-through模式
                2'b01: read_data_stage2 <= pkt_buffer[rd_ptr_q[1:0]];       // Store-and-forward模式
                default: read_data_stage2 <= read_data_stage1;
            endcase
        end
    end
    
    // 输出赋值
    assign rd_data = read_data_stage2;

endmodule