//SystemVerilog
module rle_buffer #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] din,
    output reg [2*DW-1:0] dout
);
    // 内部信号声明
    reg [DW-1:0] prev;         // 存储前一个输入值
    reg [DW-1:0] count;        // 当前相同值的计数
    reg update_output;         // 输出更新标志
    reg data_changed;          // 数据变化指示器
    
    // 初始化寄存器
    initial begin
        count = 0;
        prev = 0;
        update_output = 0;
        data_changed = 0;
    end
    
    // 数据变化检测逻辑
    always @(posedge clk) begin
        if (en) begin
            data_changed <= (din != prev);
        end else begin
            data_changed <= 0;
        end
    end
    
    // 计数器逻辑 - 跟踪相同值的出现次数
    always @(posedge clk) begin
        if (en) begin
            if (din == prev) begin
                count <= count + 1'b1;
            end else begin
                count <= 1'b1;
            end
        end
    end
    
    // 数据存储逻辑 - 更新前一个值
    always @(posedge clk) begin
        if (en && (din != prev)) begin
            prev <= din;
        end
    end
    
    // 输出更新控制逻辑
    always @(posedge clk) begin
        if (en) begin
            update_output <= data_changed;
        end else begin
            update_output <= 0;
        end
    end
    
    // 输出生成逻辑 - 产生RLE编码
    always @(posedge clk) begin
        if (en && update_output) begin
            dout <= {count, prev};
        end
    end
    
endmodule