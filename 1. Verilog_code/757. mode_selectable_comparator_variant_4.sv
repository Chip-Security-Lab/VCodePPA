//SystemVerilog
module mode_selectable_comparator (
    input wire clk,                // 添加时钟输入用于流水线寄存器
    input wire rst_n,              // 添加复位信号
    input wire [15:0] input_a,     // 输入数据A
    input wire [15:0] input_b,     // 输入数据B
    input wire signed_mode,        // 0=无符号比较, 1=有符号比较
    output reg is_equal,           // 相等结果
    output reg is_greater,         // 大于结果
    output reg is_less             // 小于结果
);

    // 第一级流水线：寄存数据输入和控制信号
    reg [15:0] input_a_r1;
    reg [15:0] input_b_r1;
    reg signed_mode_r1;
    
    // 第二级流水线：保存比较结果
    reg equal_r2;
    reg greater_r2;
    reg less_r2;

    // 分离无符号和有符号比较的数据路径
    wire unsigned_comparison_path;
    wire signed_comparison_path;
    
    // 比较结果线网
    wire comparison_equal;
    wire comparison_greater;
    wire comparison_less;
    
    // 第一级流水线：寄存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_a_r1 <= 16'b0;
            input_b_r1 <= 16'b0;
            signed_mode_r1 <= 1'b0;
        end else begin
            input_a_r1 <= input_a;
            input_b_r1 <= input_b;
            signed_mode_r1 <= signed_mode;
        end
    end
    
    // 分离比较路径，减少路径深度
    assign unsigned_comparison_path = !signed_mode_r1;
    assign signed_comparison_path = signed_mode_r1;
    
    // 采用共享比较结构优化资源使用
    assign comparison_equal = (input_a_r1 == input_b_r1);
    
    // 根据模式选择适当的比较类型
    assign comparison_greater = signed_comparison_path ? 
                               ($signed(input_a_r1) > $signed(input_b_r1)) : 
                               (input_a_r1 > input_b_r1);
                               
    assign comparison_less = signed_comparison_path ? 
                            ($signed(input_a_r1) < $signed(input_b_r1)) : 
                            (input_a_r1 < input_b_r1);
    
    // 第二级流水线：寄存比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal_r2 <= 1'b0;
            greater_r2 <= 1'b0;
            less_r2 <= 1'b0;
        end else begin
            equal_r2 <= comparison_equal;
            greater_r2 <= comparison_greater;
            less_r2 <= comparison_less;
        end
    end
    
    // 第三级流水线：输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_equal <= 1'b0;
            is_greater <= 1'b0;
            is_less <= 1'b0;
        end else begin
            is_equal <= equal_r2;
            is_greater <= greater_r2;
            is_less <= less_r2;
        end
    end

endmodule