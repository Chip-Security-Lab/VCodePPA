//SystemVerilog
module serial2parallel_converter #(
    parameter WORD_SIZE = 8
) (
    input  wire clk,
    input  wire n_reset,
    input  wire serial_in,
    input  wire load_en,
    output wire [WORD_SIZE-1:0] parallel_out,
    output wire conversion_done
);
    reg [WORD_SIZE-1:0] shift_reg;
    reg [$clog2(WORD_SIZE)-1:0] bit_counter;
    
    // 优化高扇出信号的缓冲策略
    reg [$clog2(WORD_SIZE)-1:0] bit_counter_buf;
    reg conversion_done_reg;
    
    // 预计算完成状态信号
    reg next_done;
    
    assign parallel_out = shift_reg;
    assign conversion_done = conversion_done_reg;
    
    // 使用参数定义计数器终值常量，提高可读性和性能
    localparam CNT_MAX = WORD_SIZE - 1;
    
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            shift_reg <= {WORD_SIZE{1'b0}};
            bit_counter <= {$clog2(WORD_SIZE){1'b0}};
            bit_counter_buf <= {$clog2(WORD_SIZE){1'b0}};
            conversion_done_reg <= 1'b0;
            next_done <= 1'b0;
        end else if (load_en) begin
            // 优化移位寄存器操作
            shift_reg <= {shift_reg[WORD_SIZE-2:0], serial_in};
            
            // 优化计数器比较逻辑
            next_done <= (bit_counter == (CNT_MAX - 1));
            conversion_done_reg <= next_done;
            
            // 针对FPGA/ASIC结构优化的计数器复位逻辑
            if (bit_counter == CNT_MAX) begin
                bit_counter <= {$clog2(WORD_SIZE){1'b0}};
            end else begin
                bit_counter <= bit_counter + 1'b1;
            end
            
            // 简化缓冲策略，减少寄存器使用量
            bit_counter_buf <= bit_counter;
        end
    end
endmodule