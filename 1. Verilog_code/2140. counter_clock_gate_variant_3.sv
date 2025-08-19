//SystemVerilog
module counter_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [3:0] div_ratio,
    output wire clk_out
);
    // 流水线寄存器
    reg [3:0] cnt_stage1;
    reg [3:0] div_ratio_stage1; 
    reg equal_flag_stage2;
    reg clk_enable_stage3;
    
    // 阶段1: 计数器逻辑 - 优化比较和计数逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 4'b0;
            div_ratio_stage1 <= 4'b0;
        end
        else begin
            div_ratio_stage1 <= div_ratio;
            // 优化比较链，直接比较
            if (cnt_stage1 >= div_ratio_stage1) 
                cnt_stage1 <= 4'b0;
            else
                cnt_stage1 <= cnt_stage1 + 1'b1;
        end
    end
    
    // 阶段2: 简化比较逻辑，零检查更高效
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            equal_flag_stage2 <= 1'b1; // 复位后使能第一个周期
        end
        else begin
            // 直接检测零值，无需额外寄存器存储div_ratio
            equal_flag_stage2 <= (cnt_stage1 == 4'b0);
        end
    end
    
    // 阶段3: 输出使能逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_enable_stage3 <= 1'b0;
        end
        else begin
            clk_enable_stage3 <= equal_flag_stage2;
        end
    end
    
    // 使用逻辑与实现时钟门控
    assign clk_out = clk_in & clk_enable_stage3;
endmodule