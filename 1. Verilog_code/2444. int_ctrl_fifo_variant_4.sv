//SystemVerilog
module int_ctrl_fifo #(
    parameter DEPTH = 4,
    parameter DW = 8
)(
    input wire clk,
    input wire wr_en,
    input wire rd_en,
    input wire [DW-1:0] int_data,
    output wire full,
    output wire empty,
    output reg [DW-1:0] int_out
);

    // 内部存储和指针寄存器
    reg [DW-1:0] fifo [0:DEPTH-1];
    reg [1:0] wr_ptr, rd_ptr;
    wire wr_enable, rd_enable;
    
    // 组合逻辑部分 - 状态标志生成
    // 使用条件求和减法算法实现指针差值计算
    wire [1:0] ptr_diff;
    wire borrow_0, borrow_1;
    
    // 条件求和减法器实现 (wr_ptr - rd_ptr)
    assign borrow_0 = wr_ptr[0] < rd_ptr[0];
    assign ptr_diff[0] = wr_ptr[0] ^ rd_ptr[0];
    
    assign borrow_1 = (wr_ptr[1] < rd_ptr[1]) | ((wr_ptr[1] == rd_ptr[1]) & borrow_0);
    assign ptr_diff[1] = wr_ptr[1] ^ rd_ptr[1] ^ borrow_0;
    
    // 基于条件求和减法结果的状态标志
    assign empty = (ptr_diff == 2'b00) & ~borrow_1;
    assign full = (ptr_diff == 2'b11) & ~borrow_1;
    
    // 组合逻辑部分 - 使能控制
    assign wr_enable = wr_en & ~full;
    assign rd_enable = rd_en & ~empty;
    
    // 时序逻辑部分 - 写指针更新
    always @(posedge clk) begin
        if (wr_enable) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    
    // 时序逻辑部分 - 读指针更新
    always @(posedge clk) begin
        if (rd_enable) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    // 时序逻辑部分 - 数据写入
    always @(posedge clk) begin
        if (wr_enable) begin
            fifo[wr_ptr] <= int_data;
        end
    end
    
    // 时序逻辑部分 - 数据读出
    always @(posedge clk) begin
        if (rd_enable) begin
            int_out <= fifo[rd_ptr];
        end
    end

endmodule