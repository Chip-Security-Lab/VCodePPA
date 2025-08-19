//SystemVerilog
module pl_reg_bound #(parameter W=8, MAX=8'h7F) (
    input wire clk,
    input wire rst_n,       // 复位信号
    input wire valid_in,    // 数据有效输入信号
    input wire ready_out,   // 下游模块就绪信号
    output wire ready_in,   // 向上游模块指示就绪状态
    input wire [W-1:0] d_in,
    output wire valid_out,  // 输出数据有效信号
    output wire [W-1:0] q
);

    // 流水线阶段1：比较和选择逻辑
    reg [W-1:0] stage1_data;
    reg stage1_valid;
    wire stage1_ready;
    wire [W-1:0] bounded_data;
    wire exceed_max;
    
    // 优化比较逻辑 - 使用位扩展和单向比较
    // 通过明确制定比较操作的方向，优化比较器的实现
    assign exceed_max = (d_in > MAX);
    assign bounded_data = exceed_max ? MAX : d_in;
    
    // 流水线阶段2：输出寄存器
    reg [W-1:0] stage2_data;
    reg stage2_valid;
    wire stage2_ready;
    
    // 流水线控制逻辑 - 优化控制流
    assign stage2_ready = ready_out;  // 输出就绪依赖下游模块
    assign stage1_ready = ~stage2_valid | stage2_ready;  // 使用位操作优化
    assign ready_in = ~stage1_valid | stage1_ready;  // 使用位操作优化
    
    assign valid_out = stage2_valid;
    assign q = stage2_data;
    
    // 流水线阶段1寄存器 - 优化状态转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage1_data <= {W{1'b0}};
        end else if (ready_in && valid_in) begin
            // 新数据进入阶段1并进行边界检查
            stage1_data <= bounded_data;
            stage1_valid <= 1'b1;
        end else if (stage1_ready && stage1_valid) begin
            // 数据已移至阶段2，清空阶段1
            stage1_valid <= 1'b0;
        end
    end
    
    // 流水线阶段2寄存器 - 优化状态转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
            stage2_data <= {W{1'b0}};
        end else if (stage1_ready && stage1_valid) begin
            // 从阶段1加载边界检查后的数据
            stage2_data <= stage1_data;
            stage2_valid <= 1'b1;
        end else if (stage2_ready && stage2_valid) begin
            // 数据已输出，清空阶段2
            stage2_valid <= 1'b0;
        end
    end

endmodule