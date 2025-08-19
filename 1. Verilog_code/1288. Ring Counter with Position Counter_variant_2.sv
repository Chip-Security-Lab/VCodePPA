//SystemVerilog - IEEE 1364-2005 standard
module counting_ring_counter(
    input wire clock,
    input wire reset,
    output reg [3:0] ring_out,
    output reg [1:0] position // Position of the '1' bit
);
    // 中间流水线寄存器
    reg [3:0] ring_stage1;
    reg [1:0] position_stage1;
    reg [3:0] ring_stage2;
    reg [1:0] position_stage2;
    
    // 为高扇出的复位信号添加缓冲寄存器
    reg reset_buf1, reset_buf2, reset_buf3;
    
    // 复位信号缓冲器
    always @(posedge clock) begin
        reset_buf1 <= reset;
        reset_buf2 <= reset_buf1;
        reset_buf3 <= reset_buf1;
    end
    
    // 第一级流水线 - 处理输入和初始变换
    always @(posedge clock) begin
        if (reset_buf1) begin
            ring_stage1 <= 4'b0001;
            position_stage1 <= 2'b00;
        end else if (!reset_buf1) begin
            // 第一级变换
            ring_stage1 <= {ring_out[2:0], ring_out[3]};
            position_stage1 <= (position == 2'b11) ? 2'b00 : position + 1;
        end
    end
    
    // 第二级流水线 - 进一步处理
    always @(posedge clock) begin
        if (reset_buf2) begin
            ring_stage2 <= 4'b0001;
            position_stage2 <= 2'b00;
        end else if (!reset_buf2) begin
            ring_stage2 <= ring_stage1;
            position_stage2 <= position_stage1;
        end
    end
    
    // 第三级流水线 - 最终输出
    always @(posedge clock) begin
        if (reset_buf3) begin
            ring_out <= 4'b0001;
            position <= 2'b00;
        end else if (!reset_buf3) begin
            ring_out <= ring_stage2;
            position <= position_stage2;
        end
    end
endmodule