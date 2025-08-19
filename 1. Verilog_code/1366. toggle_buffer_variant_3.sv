//SystemVerilog
module toggle_buffer (
    input wire clk,
    input wire toggle,
    input wire [15:0] data_in,
    input wire write_en,
    output wire [15:0] data_out
);
    // 双缓冲区
    reg [15:0] buffer_a, buffer_b;
    
    // 流水线控制寄存器
    reg sel_stage1, sel_stage2;
    reg [15:0] data_in_stage1;
    reg write_en_stage1;
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线：寄存选择信号和输入数据
    always @(posedge clk) begin
        // 寄存输入数据和控制信号
        data_in_stage1 <= data_in;
        write_en_stage1 <= write_en;
        valid_stage1 <= 1'b1;  // 数据有效标志
        
        // 处理选择信号
        if (toggle)
            sel_stage1 <= ~sel_stage1;
        else
            sel_stage1 <= sel_stage1;
    end
    
    // 第二级流水线：写入缓冲区并准备输出
    always @(posedge clk) begin
        // 将控制信号传递到下一级
        sel_stage2 <= sel_stage1;
        valid_stage2 <= valid_stage1;
        
        // 写入缓冲区逻辑
        if (write_en_stage1 && sel_stage1)
            buffer_a <= data_in_stage1;
        else if (write_en_stage1 && !sel_stage1)
            buffer_b <= data_in_stage1;
    end
    
    // 输出多路复用器
    assign data_out = (valid_stage2) ? (sel_stage2 ? buffer_b : buffer_a) : 16'b0;
    
endmodule