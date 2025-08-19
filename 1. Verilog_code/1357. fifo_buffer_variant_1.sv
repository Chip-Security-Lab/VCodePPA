//SystemVerilog
module fifo_buffer #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input wire clk, rst,
    input wire [WIDTH-1:0] data_in,
    input wire push, pop,
    output wire [WIDTH-1:0] data_out,
    output wire empty, full
);
    // 内部连线
    wire [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    wire [$clog2(DEPTH):0] count;
    
    // 状态控制子模块
    fifo_controller #(
        .DEPTH(DEPTH)
    ) controller_inst (
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .full(full),
        .empty(empty),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .count(count)
    );
    
    // 存储器子模块
    fifo_memory #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) memory_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .push(push),
        .pop(pop),
        .full(full),
        .empty(empty)
    );
    
endmodule

// 控制器模块 - 负责指针和计数器管理
module fifo_controller #(
    parameter DEPTH = 8
)(
    input wire clk, rst,
    input wire push, pop,
    output wire full, empty,
    output reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr,
    output reg [$clog2(DEPTH):0] count
);
    // 状态标志
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
    // 中间信号声明
    reg wr_en, rd_en;
    reg [$clog2(DEPTH)-1:0] next_wr_ptr, next_rd_ptr;
    reg [$clog2(DEPTH):0] next_count;
    reg wr_wrap, rd_wrap;
    
    // 使能信号逻辑
    always @(*) begin
        wr_en = push && !full;
        rd_en = pop && !empty;
    end
    
    // 计算下一个写指针值
    always @(*) begin
        wr_wrap = (wr_ptr == DEPTH-1);
        if (wr_wrap)
            next_wr_ptr = 0;
        else
            next_wr_ptr = wr_ptr + 1;
    end
    
    // 计算下一个读指针值
    always @(*) begin
        rd_wrap = (rd_ptr == DEPTH-1);
        if (rd_wrap)
            next_rd_ptr = 0;
        else
            next_rd_ptr = rd_ptr + 1;
    end
    
    // 计算下一个计数值
    always @(*) begin
        case ({wr_en, rd_en})
            2'b00: next_count = count;        // 无操作
            2'b01: next_count = count - 1;    // 仅读
            2'b10: next_count = count + 1;    // 仅写
            2'b11: next_count = count;        // 同时读写
        endcase
    end
    
    // 同步更新寄存器
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (wr_en)
                wr_ptr <= next_wr_ptr;
                
            if (rd_en)
                rd_ptr <= next_rd_ptr;
                
            count <= next_count;
        end
    end
endmodule

// 存储器模块 - 负责数据存储和访问
module fifo_memory #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input wire clk, rst,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,
    input wire [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr,
    input wire push, pop,
    input wire full, empty
);
    // 存储单元
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // 中间信号定义
    reg write_enable, read_enable;
    
    // 控制信号生成逻辑
    always @(*) begin
        write_enable = push && !full;
        read_enable = pop && !empty;
    end
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_enable) begin
            memory[wr_ptr] <= data_in;
        end
    end
    
    // 读取逻辑
    always @(posedge clk) begin
        if (read_enable) begin
            data_out <= memory[rd_ptr];
        end
    end
endmodule