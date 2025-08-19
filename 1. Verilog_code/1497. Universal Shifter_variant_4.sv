//SystemVerilog
module universal_shifter (
    input wire clk, rst,
    input wire [1:0] mode, // 00:hold, 01:shift right, 10:shift left, 11:load
    input wire [3:0] parallel_in,
    input wire left_in, right_in,
    output reg [3:0] q
);
    // 第一级流水线寄存器
    reg [1:0] mode_stage1;
    reg [3:0] parallel_in_stage1;
    reg left_in_stage1, right_in_stage1;
    
    // q信号的缓冲寄存器，减少扇出负载
    reg [3:0] q_buf1, q_buf2, q_buf3;
    reg [3:0] q_stage1;
    
    // 第二级流水线寄存器
    reg [1:0] mode_stage2;
    reg [3:0] parallel_in_stage2;
    reg left_in_stage2, right_in_stage2;
    reg [3:0] q_stage2;
    
    // 中间计算结果寄存器
    reg [3:0] shift_right_result_stage1;
    reg [3:0] shift_left_result_stage1;
    
    // b0000和b0的缓冲寄存器
    reg [3:0] zero_buf1, zero_buf2;
    reg zero_bit_buf1, zero_bit_buf2;
    
    // 高扇出信号缓冲初始化
    always @(posedge clk) begin
        if (rst) begin
            q_buf1 <= 4'b0000;
            q_buf2 <= 4'b0000;
            q_buf3 <= 4'b0000;
            zero_buf1 <= 4'b0000;
            zero_buf2 <= 4'b0000;
            zero_bit_buf1 <= 1'b0;
            zero_bit_buf2 <= 1'b0;
        end else begin
            q_buf1 <= q;
            q_buf2 <= q;
            q_buf3 <= q;
            zero_buf1 <= 4'b0000;
            zero_buf2 <= 4'b0000;
            zero_bit_buf1 <= 1'b0;
            zero_bit_buf2 <= 1'b0;
        end
    end
    
    // 第一级流水线 - 捕获输入并计算可能的移位结果
    always @(posedge clk) begin
        if (rst) begin
            mode_stage1 <= 2'b00;
            parallel_in_stage1 <= 4'b0000;
            left_in_stage1 <= 1'b0;
            right_in_stage1 <= 1'b0;
            q_stage1 <= 4'b0000;
            shift_right_result_stage1 <= 4'b0000;
            shift_left_result_stage1 <= 4'b0000;
        end else begin
            mode_stage1 <= mode;
            parallel_in_stage1 <= parallel_in;
            left_in_stage1 <= left_in;
            right_in_stage1 <= right_in;
            q_stage1 <= q_buf1; // 使用缓冲版本
            
            // 预计算可能的移位结果，使用缓冲版本的q
            shift_right_result_stage1 <= {right_in, q_buf2[3:1]};
            shift_left_result_stage1 <= {q_buf3[2:0], left_in};
        end
    end
    
    // 第二级流水线 - 传递中间结果
    always @(posedge clk) begin
        if (rst) begin
            mode_stage2 <= 2'b00;
            parallel_in_stage2 <= 4'b0000;
            left_in_stage2 <= 1'b0;
            right_in_stage2 <= 1'b0;
            q_stage2 <= 4'b0000;
        end else begin
            mode_stage2 <= mode_stage1;
            parallel_in_stage2 <= parallel_in_stage1;
            left_in_stage2 <= left_in_stage1;
            right_in_stage2 <= right_in_stage1;
            q_stage2 <= q_stage1;
        end
    end
    
    // 第三级流水线 - 最终选择和输出
    // 使用层次化的复用器结构减少关键路径延迟
    reg [3:0] mux_result;
    
    always @(*) begin
        case (mode_stage2)
            2'b00: mux_result = q_stage2;                 // Hold
            2'b01: mux_result = shift_right_result_stage1; // Shift right
            2'b10: mux_result = shift_left_result_stage1;  // Shift left
            2'b11: mux_result = parallel_in_stage2;        // Parallel load
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            q <= zero_buf1; // 使用缓冲的零值
        end else begin
            q <= mux_result;
        end
    end
endmodule