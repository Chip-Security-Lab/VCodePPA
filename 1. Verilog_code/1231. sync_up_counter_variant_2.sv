//SystemVerilog
module sync_counter_up (
    input clk,
    input reset,
    input enable,
    output reg [7:0] count
);
    // 第一级流水线寄存器 - 输入捕获
    reg enable_stage1;
    
    // 第二级流水线寄存器 - 中间计算
    reg enable_stage2;
    reg [7:0] count_stage1;
    
    // 第三级流水线寄存器 - 计算结果
    reg [3:0] count_lower_stage2;
    reg [3:0] count_upper_stage2;
    reg [3:0] count_lower_stage3;
    
    // 第一级流水线 - 捕获输入
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            enable_stage1 <= 1'b0;
            count_stage1 <= 8'b0;
        end else begin
            enable_stage1 <= enable;
            count_stage1 <= count;
        end
    end
    
    // 第二级流水线 - 中间计算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            enable_stage2 <= 1'b0;
            count_lower_stage2 <= 4'b0;
            count_upper_stage2 <= 4'b0;
        end else begin
            enable_stage2 <= enable_stage1;
            // 将计数器拆分为上下两部分单独处理，降低关键路径
            if (enable_stage1) begin
                // 处理低4位
                count_lower_stage2 <= count_stage1[3:0] + 4'b1;
                // 预处理高4位
                count_upper_stage2 <= count_stage1[7:4];
            end else begin
                count_lower_stage2 <= count_stage1[3:0];
                count_upper_stage2 <= count_stage1[7:4];
            end
        end
    end
    
    // 第三级流水线 - 进位处理和最终结果
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count_lower_stage3 <= 4'b0;
            count <= 8'b0;
        end else begin
            count_lower_stage3 <= count_lower_stage2;
            
            if (enable_stage2) begin
                // 低4位保持第二级的结果
                count[3:0] <= count_lower_stage2;
                
                // 处理高4位及进位
                if (count_lower_stage2 == 4'hF && count_stage1[3:0] != 4'hF)
                    count[7:4] <= count_upper_stage2 + 4'b1;
                else
                    count[7:4] <= count_upper_stage2;
            end else begin
                count <= {count_upper_stage2, count_lower_stage2};
            end
        end
    end
endmodule