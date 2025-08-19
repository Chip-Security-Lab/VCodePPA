//SystemVerilog
module ring_counter_param #(parameter WIDTH=4) (
    input wire clk,
    input wire rst,
    input wire valid_in,    // 输入有效信号
    output wire ready_out,  // 输出就绪信号
    output wire valid_out,  // 输出有效信号
    output wire [WIDTH-1:0] counter_out // 计数器输出
);

    // 流水线寄存器
    reg [WIDTH-1:0] stage1_counter;
    reg [WIDTH-1:0] stage2_counter;
    reg [WIDTH-1:0] stage3_counter;
    
    // 流水线控制信号
    reg stage1_valid;
    reg stage2_valid;
    reg stage3_valid;
    
    // 环形移位专用信号
    wire [WIDTH-1:0] initial_value;
    wire [WIDTH-1:0] rotated_value;
    
    // 固定初始值
    assign initial_value = {{WIDTH-1{1'b0}}, 1'b1};
    
    // 准备接收新数据
    assign ready_out = 1'b1; // 该设计总是可以接收新数据
    assign valid_out = stage3_valid;
    assign counter_out = stage3_counter;
    
    // 使用借位算法实现环形移位
    // 对于环形右移，我们将最低位移到最高位
    assign rotated_value[WIDTH-1] = stage1_counter[0];
    
    // 生成剩余位的移位逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH-1; i = i + 1) begin : shift_gen
            assign rotated_value[i] = stage1_counter[i+1];
        end
    endgenerate
    
    // 流水线第一级：接收输入并更新计数初值
    always @(posedge clk) begin
        if (rst) begin
            stage1_counter <= initial_value;
            stage1_valid <= 1'b0;
        end else begin
            if (valid_in && ready_out) begin
                stage1_counter <= initial_value; // 复位初始值
                stage1_valid <= 1'b1;
            end else if (stage1_valid) begin
                stage1_counter <= rotated_value;
                stage1_valid <= 1'b1;
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // 流水线第二级：中间处理阶段
    always @(posedge clk) begin
        if (rst) begin
            stage2_counter <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            stage2_counter <= stage1_counter;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 流水线第三级：输出阶段
    always @(posedge clk) begin
        if (rst) begin
            stage3_counter <= {WIDTH{1'b0}};
            stage3_valid <= 1'b0;
        end else begin
            stage3_counter <= stage2_counter;
            stage3_valid <= stage2_valid;
        end
    end

endmodule