//SystemVerilog
module wildcard_pattern_matcher #(
    parameter WIDTH = 8
)(
    input  wire clk,                  // 添加时钟信号用于流水线寄存器
    input  wire rst_n,                // 添加复位信号
    input  wire [WIDTH-1:0] data,     // 输入数据
    input  wire [WIDTH-1:0] pattern,  // 匹配模式
    input  wire [WIDTH-1:0] mask,     // 掩码位 (1=忽略位, 0=匹配位)
    output reg  match_result          // 匹配结果
);
    // 第一级流水线 - 掩码应用阶段
    reg [WIDTH-1:0] masked_data_r;
    reg [WIDTH-1:0] masked_pattern_r;
    
    // 第二级流水线 - 比较阶段
    reg match_condition;
    
    // 阶段1: 应用掩码 - 分割复杂组合逻辑路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_r <= {WIDTH{1'b0}};
            masked_pattern_r <= {WIDTH{1'b0}};
        end else begin
            // 掩码: 0 = 关心此位, 1 = 不关心此位
            masked_data_r <= data & ~mask;
            masked_pattern_r <= pattern & ~mask;
        end
    end
    
    // 阶段2: 比较操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_condition <= 1'b0;
        end else begin
            match_condition <= (masked_data_r == masked_pattern_r);
        end
    end
    
    // 阶段3: 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_result <= 1'b0;
        end else begin
            match_result <= match_condition;
        end
    end

endmodule