//SystemVerilog
module FIFO_Controller #(
    parameter DEPTH = 16,
    parameter DATA_WIDTH = 8,
    parameter AF_THRESH = 12,
    parameter AE_THRESH = 4
)(
    input clk, rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output full,
    output empty,
    output almost_full,
    output almost_empty
);
    // 内存和指针定义
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [4:0] wr_ptr, rd_ptr;
    reg [4:0] count;
    
    // 预计算下一个指针位置，减少关键路径延迟
    wire [4:0] next_wr_ptr = (wr_ptr == DEPTH-1) ? 5'b0 : wr_ptr + 1'b1;
    wire [4:0] next_rd_ptr = (rd_ptr == DEPTH-1) ? 5'b0 : rd_ptr + 1'b1;
    
    // 状态信号优化 - 分解复杂条件，并行计算
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    
    // 将阈值比较拆分，减少比较器延迟
    assign almost_full = (count[4:3] == 2'b11) || ((count[4:3] == 2'b10) && (count[2:0] >= (AF_THRESH - 8)));
    assign almost_empty = (count[4:3] == 2'b00) && (count[2:0] <= AE_THRESH);
    
    // 状态信号计算 - 并行计算，减少逻辑依赖
    wire can_write = wr_en & ~full;
    wire can_read = rd_en & ~empty;
    
    // 写入逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 5'b0;
        end else if (can_write) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= next_wr_ptr;
        end
    end
    
    // 读取逻辑 - 读数据前移，减少关键路径
    reg [DATA_WIDTH-1:0] pre_data_out;
    
    always @(*) begin
        pre_data_out = mem[rd_ptr];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 5'b0;
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (can_read) begin
            data_out <= pre_data_out;
            rd_ptr <= next_rd_ptr;
        end
    end
    
    // 计数器逻辑 - 使用并行前缀减法器实现
    wire [1:0] count_ctrl = {can_write, can_read};
    wire count_inc = count_ctrl == 2'b10;
    wire count_dec = count_ctrl == 2'b01;
    
    // 前缀减法器逻辑
    wire [4:0] subtrahend = 5'b00001; // 减数为1
    wire [4:0] count_minus_1;
    wire [4:0] propagate, generate_bits;
    wire [4:0] carry;
    
    // 计算生成位和传播位
    assign propagate = count ^ 5'b11111; // ~count
    assign generate_bits = ~count & subtrahend;
    
    // 并行前缀进位计算
    assign carry[0] = generate_bits[0];
    assign carry[1] = generate_bits[1] | (propagate[1] & carry[0]);
    assign carry[2] = generate_bits[2] | (propagate[2] & carry[1]);
    assign carry[3] = generate_bits[3] | (propagate[3] & carry[2]);
    assign carry[4] = generate_bits[4] | (propagate[4] & carry[3]);
    
    // 计算差值
    assign count_minus_1 = count ^ propagate ^ {carry[3:0], 1'b0};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 5'b0;
        end else begin
            if (count_inc)
                count <= count + 1'b1;
            else if (count_dec)
                count <= count_minus_1;
            // 其他情况保持不变
        end
    end
endmodule