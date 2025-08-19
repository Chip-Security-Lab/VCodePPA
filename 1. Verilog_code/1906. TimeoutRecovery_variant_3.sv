//SystemVerilog
module TimeoutRecovery #(parameter WIDTH=8, TIMEOUT=32'hFFFF) (
    input clk, rst_n,
    input [WIDTH-1:0] unstable_in,
    output reg [WIDTH-1:0] stable_out,
    output reg timeout
);
    // 流水线第一级：检测信号差异并初始化计数器
    reg [WIDTH-1:0] unstable_in_stage1;
    reg [WIDTH-1:0] stable_out_stage1;
    reg is_different_stage1;
    
    // 流水线第二级：计数器加法操作分解为两步
    reg [31:0] counter_stage2;
    reg [15:0] counter_low_plus_one_stage2;  // 低16位加法
    reg [15:0] counter_high_stage2;          // 高16位
    reg carry_stage2;                        // 进位标志
    reg is_different_stage2;
    
    // 中间流水线级：处理高位加法和进位
    reg [15:0] counter_low_stage2_5;
    reg [15:0] counter_high_plus_carry_stage2_5;
    reg is_different_stage2_5;
    
    // 流水线第三级：计数器更新和超时检测分解
    reg [31:0] counter_stage3;
    reg [31:0] counter_next_stage3;
    reg is_different_stage3;
    
    // 超时检测流水线子阶段
    reg timeout_compare_low_stage3;  // 低16位比较结果
    reg timeout_compare_high_stage3; // 高16位比较结果
    
    // 流水线第四级：超时条件判断和输出更新
    reg [31:0] counter_stage4;
    reg timeout_condition_stage4;
    reg [WIDTH-1:0] unstable_in_stage4;
    reg [WIDTH-1:0] stable_out_stage4;
    
    // 常量分解
    wire [15:0] TIMEOUT_LOW = TIMEOUT[15:0];
    wire [15:0] TIMEOUT_HIGH = TIMEOUT[31:16];
    
    // 流水线第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unstable_in_stage1 <= {WIDTH{1'b0}};
            stable_out_stage1 <= {WIDTH{1'b0}};
            is_different_stage1 <= 1'b0;
        end else begin
            unstable_in_stage1 <= unstable_in;
            stable_out_stage1 <= stable_out;
            is_different_stage1 <= (unstable_in != stable_out);
        end
    end
    
    // 流水线第二级 - 优化加法路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 32'h00000000;
            counter_low_plus_one_stage2 <= 16'h0000;
            counter_high_stage2 <= 16'h0000;
            carry_stage2 <= 1'b0;
            is_different_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage4; // 使用最新的计数器值
            // 低16位加法和进位计算
            {carry_stage2, counter_low_plus_one_stage2} <= counter_stage4[15:0] + 16'h0001;
            counter_high_stage2 <= counter_stage4[31:16];
            is_different_stage2 <= is_different_stage1;
        end
    end
    
    // 新增中间流水线级 - 处理高位加法
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_low_stage2_5 <= 16'h0000;
            counter_high_plus_carry_stage2_5 <= 16'h0000;
            is_different_stage2_5 <= 1'b0;
        end else begin
            counter_low_stage2_5 <= counter_low_plus_one_stage2;
            // 高16位加上进位
            counter_high_plus_carry_stage2_5 <= counter_high_stage2 + {15'b0, carry_stage2};
            is_different_stage2_5 <= is_different_stage2;
        end
    end
    
    // 流水线第三级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage3 <= 32'h00000000;
            counter_next_stage3 <= 32'h00000000;
            is_different_stage3 <= 1'b0;
            timeout_compare_low_stage3 <= 1'b0;
            timeout_compare_high_stage3 <= 1'b0;
        end else begin
            counter_stage3 <= {counter_high_plus_carry_stage2_5, counter_low_stage2_5};
            // 根据差异决定计数器值
            counter_next_stage3 <= is_different_stage2_5 ? 32'h00000000 : 
                                  {counter_high_plus_carry_stage2_5, counter_low_stage2_5};
            is_different_stage3 <= is_different_stage2_5;
            
            // 分解超时检测逻辑为两部分
            timeout_compare_low_stage3 <= (counter_low_stage2_5 >= TIMEOUT_LOW);
            timeout_compare_high_stage3 <= (counter_high_plus_carry_stage2_5 >= TIMEOUT_HIGH);
        end
    end
    
    // 流水线第四级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage4 <= 32'h00000000;
            timeout_condition_stage4 <= 1'b0;
            unstable_in_stage4 <= {WIDTH{1'b0}};
            stable_out_stage4 <= {WIDTH{1'b0}};
        end else begin
            counter_stage4 <= counter_next_stage3;
            // 优化的超时检测条件
            timeout_condition_stage4 <= (timeout_compare_high_stage3 && 
                                       (counter_high_plus_carry_stage2_5 > TIMEOUT_HIGH || 
                                        timeout_compare_low_stage3));
            unstable_in_stage4 <= unstable_in_stage1;
            stable_out_stage4 <= stable_out_stage1;
        end
    end
    
    // 最终输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_out <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else begin
            timeout <= timeout_condition_stage4;
            stable_out <= timeout_condition_stage4 ? stable_out_stage4 : unstable_in_stage4;
        end
    end
endmodule