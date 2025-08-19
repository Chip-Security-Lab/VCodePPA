//SystemVerilog
// IEEE 1364-2005 Verilog
module circular_shift_buffer #(parameter SIZE = 8, WIDTH = 4) (
    input wire clk, reset, write_en,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 缓冲区存储
    reg [WIDTH-1:0] buffer [0:SIZE-1];
    
    // 指针寄存器
    reg [$clog2(SIZE)-1:0] read_ptr_stage1, read_ptr_stage2;
    reg [$clog2(SIZE)-1:0] write_ptr;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg [WIDTH-1:0] data_in_stage1;
    
    // 用于指针更新的补码加法实现
    wire [$clog2(SIZE)-1:0] next_read_ptr;
    wire [$clog2(SIZE)-1:0] next_write_ptr;
    wire [$clog2(SIZE)-1:0] increment_value;
    wire [$clog2(SIZE)-1:0] size_minus_one;
    
    // 使用补码加法计算下一个指针位置
    assign increment_value = 1;
    assign size_minus_one = SIZE - 1;
    
    // 使用补码加法实现指针递增
    assign next_read_ptr = (read_ptr_stage1 == size_minus_one) ? 0 : read_ptr_stage1 + increment_value;
    assign next_write_ptr = (write_ptr == size_minus_one) ? 0 : write_ptr + increment_value;
    
    // 阶段1: 数据和指针处理
    always @(posedge clk) begin
        if (reset) begin
            write_ptr <= 0;
            read_ptr_stage1 <= 0;
            valid_stage1 <= 0;
            data_in_stage1 <= 0;
        end else begin
            valid_stage1 <= write_en;
            
            if (write_en) begin
                data_in_stage1 <= data_in;
                read_ptr_stage1 <= next_read_ptr;
                write_ptr <= next_write_ptr;
            end
        end
    end
    
    // 阶段2: 数据写入和读取准备
    always @(posedge clk) begin
        if (reset) begin
            valid_stage2 <= 0;
            read_ptr_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            read_ptr_stage2 <= read_ptr_stage1;
            
            if (valid_stage1) begin
                buffer[write_ptr] <= data_in_stage1;
            end
        end
    end
    
    // 数据输出
    assign data_out = buffer[read_ptr_stage2];
    
endmodule