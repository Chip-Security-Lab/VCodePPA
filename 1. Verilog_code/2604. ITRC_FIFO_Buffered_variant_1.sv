//SystemVerilog
module ITRC_FIFO_Buffered #(
    parameter DW = 8,
    parameter DEPTH = 4
)(
    input clk,
    input rst_n,
    input [DW-1:0] int_in,
    input int_valid,
    output [DW-1:0] int_out,
    output empty
);
    reg [DW-1:0] fifo [0:DEPTH-1];
    reg [1:0] w_ptr, r_ptr;
    reg [1:0] w_ptr_buf1, w_ptr_buf2;
    reg [1:0] r_ptr_buf;
    
    // 写指针更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <= 2'b0;
        end
        else if (int_valid) begin
            w_ptr <= w_ptr + 2'b1;
        end
    end
    
    // 写指针第一级缓冲更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr_buf1 <= 2'b0;
        end
        else if (int_valid) begin
            w_ptr_buf1 <= w_ptr + 2'b1;
        end
    end
    
    // 写指针第二级缓冲更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr_buf2 <= 2'b0;
        end
        else if (int_valid) begin
            w_ptr_buf2 <= w_ptr_buf1;
        end
    end
    
    // 读指针更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr <= 2'b0;
        end
        else begin
            r_ptr <= r_ptr_buf;
        end
    end
    
    // 读指针缓冲更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr_buf <= 2'b0;
        end
        else begin
            r_ptr_buf <= r_ptr;
        end
    end
    
    // FIFO存储单元写入逻辑
    always @(posedge clk) begin
        if (int_valid) begin
            fifo[w_ptr] <= int_in;
        end
    end
    
    // 输出逻辑 - 组合逻辑
    assign int_out = fifo[r_ptr];
    assign empty = (w_ptr_buf2 == r_ptr);
endmodule