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
    // 内部信号定义
    wire [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    wire [$clog2(DEPTH):0] count;
    wire write_enable, read_enable;
    
    // 控制逻辑子模块
    fifo_control #(
        .DEPTH(DEPTH)
    ) control_unit (
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .count(count),
        .empty(empty),
        .full(full),
        .write_enable(write_enable),
        .read_enable(read_enable)
    );
    
    // 存储器子模块
    fifo_memory #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) memory_unit (
        .clk(clk),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .data_in(data_in),
        .data_out(data_out)
    );
    
endmodule

// 控制逻辑模块
module fifo_control #(
    parameter DEPTH = 8
)(
    input wire clk, rst,
    input wire push, pop,
    output reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr,
    output reg [$clog2(DEPTH):0] count,
    output wire empty, full,
    output wire write_enable, read_enable
);
    // 状态指示信号
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
    // 使能信号
    assign write_enable = push && !full;
    assign read_enable = pop && !empty;
    
    // 写指针控制
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (write_enable) begin
            wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
        end
    end
    
    // 读指针控制
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (read_enable) begin
            rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
        end
    end
    
    // 计数器控制 - 优化实现以减少逻辑路径
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            case ({write_enable, read_enable})
                2'b10: count <= count + 1; // 仅写入
                2'b01: count <= count - 1; // 仅读出
                default: count <= count;   // 同时读写或都不操作
            endcase
        end
    end
    
endmodule

// 存储器模块
module fifo_memory #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire write_enable,
    input wire read_enable,
    input wire [$clog2(DEPTH)-1:0] wr_ptr,
    input wire [$clog2(DEPTH)-1:0] rd_ptr,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // 存储器定义
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // 数据写入控制
    always @(posedge clk) begin
        if (write_enable) begin
            memory[wr_ptr] <= data_in;
        end
    end
    
    // 数据读出控制
    always @(posedge clk) begin
        if (read_enable) begin
            data_out <= memory[rd_ptr];
        end
    end
    
endmodule