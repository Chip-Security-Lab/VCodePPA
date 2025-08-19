//SystemVerilog
module char_gen (
    input wire clk, 
    input wire [9:0] h_cnt, v_cnt,
    output reg pixel, blank
);
    parameter CHAR_WIDTH = 8;
    
    // 增加流水线寄存器
    reg [9:0] h_cnt_stage1, v_cnt_stage1;
    reg [9:0] h_cnt_stage2, v_cnt_stage2;
    reg blank_stage1, blank_stage2;
    reg pixel_stage1, pixel_stage2;
    
    // 第一级流水线 - 寄存输入
    always_ff @(posedge clk) begin
        h_cnt_stage1 <= h_cnt;
        v_cnt_stage1 <= v_cnt;
    end
    
    // 第二级流水线 - 计算逻辑
    always_ff @(posedge clk) begin
        // 优化后的blank信号计算 - 使用单一比较
        blank_stage1 <= (h_cnt_stage1 >= 10'd640) || (v_cnt_stage1 >= 10'd480);
        
        // 优化后的pixel信号计算 - 使用更高效的比较方式
        pixel_stage1 <= (h_cnt_stage1[2:0] <= 3'd7);
        
        // 传递到下一级
        h_cnt_stage2 <= h_cnt_stage1;
        v_cnt_stage2 <= v_cnt_stage1;
    end
    
    // 第三级流水线 - 输出寄存器
    always_ff @(posedge clk) begin
        blank <= blank_stage1;
        pixel <= pixel_stage1;
    end
endmodule