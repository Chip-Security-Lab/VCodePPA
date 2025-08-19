//SystemVerilog
module boot_sequence_reset(
    input wire clk,
    input wire power_good,
    output wire [3:0] rst_seq,
    output wire boot_complete
);
    // 定义状态寄存器
    reg [2:0] boot_stage_r;
    reg [3:0] rst_seq_r;
    reg boot_complete_r;
    
    // 扇出缓冲寄存器 - 为高扇出信号添加缓冲
    reg [2:0] boot_stage_buf1, boot_stage_buf2;
    reg [3:0] rst_seq_buf1, rst_seq_buf2;
    
    // 生成下一个boot_stage状态的组合逻辑
    wire [2:0] next_boot_stage;
    assign next_boot_stage = (!power_good) ? 3'b0 : 
                            (boot_stage_buf1 < 3'b100) ? boot_stage_r + 1'b1 : 
                             boot_stage_r;
    
    // 生成下一个rst_seq状态的组合逻辑
    wire [3:0] next_rst_seq;
    assign next_rst_seq = (!power_good) ? 4'b1111 : 
                         (boot_stage_buf2 < 3'b100) ? rst_seq_r >> 1 : 
                          rst_seq_r;
    
    // 生成下一个boot_complete状态的组合逻辑
    wire next_boot_complete;
    assign next_boot_complete = (!power_good) ? 1'b0 : 
                               (boot_stage_r == 3'b011) ? 1'b1 : 
                                boot_complete_r;
    
    // 更新boot_stage状态寄存器
    always @(posedge clk) begin
        boot_stage_r <= next_boot_stage;
    end
    
    // 更新复位序列寄存器
    always @(posedge clk) begin
        rst_seq_r <= next_rst_seq;
    end
    
    // 更新启动完成标志寄存器
    always @(posedge clk) begin
        boot_complete_r <= next_boot_complete;
    end
    
    // 更新扇出缓冲寄存器 - 将高扇出信号分拆到多个缓冲寄存器中
    always @(posedge clk) begin
        boot_stage_buf1 <= boot_stage_r;
        boot_stage_buf2 <= boot_stage_r;
        rst_seq_buf1 <= rst_seq_r;
        rst_seq_buf2 <= rst_seq_r;
    end
    
    // 将寄存器值连接到模块输出 - 使用缓冲寄存器避免直接高扇出
    assign rst_seq = rst_seq_buf1;
    assign boot_complete = boot_complete_r;
    
endmodule