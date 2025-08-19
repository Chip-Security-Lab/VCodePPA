//SystemVerilog
//IEEE 1364-2005
module circular_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    input wire read_en,
    output reg [7:0] data_out,
    output reg empty,
    output reg full
);
    // 内存与指针定义
    reg [7:0] buffer_mem [0:3];
    reg [1:0] write_pointer, read_pointer;
    reg [2:0] data_count;
    
    // 预计算信号 - 分解复杂表达式
    wire can_write = ~full;
    wire can_read = ~empty;
    wire write_operation = write_en & can_write;
    wire read_operation = read_en & can_read;
    wire no_change = (write_operation == read_operation);
    wire count_inc = write_operation & ~read_operation;
    wire count_dec = ~write_operation & read_operation;
    
    // 下一状态计算 - 使用并行逻辑替代case语句
    wire [2:0] next_count = (data_count & {3{no_change}}) | 
                           ((data_count + 3'd1) & {3{count_inc}}) | 
                           ((data_count - 3'd1) & {3{count_dec}});
    
    // 预先计算下一个指针值 - 减少寄存器更新路径
    wire [1:0] next_write_ptr = write_pointer + {1'b0, write_operation};
    wire [1:0] next_read_ptr = read_pointer + {1'b0, read_operation};
    
    // 状态标志预计算 - 拆分逻辑路径
    wire next_empty = (next_count == 3'd0);
    wire next_full = (next_count == 3'd4);
    
    // 统一更新所有寄存器
    always @(posedge clk) begin
        if (rst) begin
            write_pointer <= 2'd0;
            read_pointer <= 2'd0;
            data_count <= 3'd0;
            empty <= 1'b1;
            full <= 1'b0;
        end else begin
            // 更新指针和计数器
            write_pointer <= next_write_ptr;
            read_pointer <= next_read_ptr;
            data_count <= next_count;
            
            // 更新状态标志
            empty <= next_empty;
            full <= next_full;
        end
    end
    
    // 内存操作 - 数据写入和读出
    always @(posedge clk) begin
        // 写入操作
        if (write_operation) begin
            buffer_mem[write_pointer] <= data_in;
        end
        
        // 读出操作 - 并行处理，无依赖关系
        if (read_operation) begin
            data_out <= buffer_mem[read_pointer];
        end
    end
endmodule