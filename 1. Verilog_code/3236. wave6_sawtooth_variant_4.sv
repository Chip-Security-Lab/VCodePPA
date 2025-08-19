//SystemVerilog
module wave6_sawtooth #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,  // 输入控制信号，决定是否生成新的波形
    output wire             valid,   // 输出有效指示信号
    output wire [WIDTH-1:0] wave_out
);
    // 流水线阶段1: 计数器递增
    reg [WIDTH-1:0] counter_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 中间处理
    reg [WIDTH-1:0] counter_stage2;
    reg valid_stage2;
    
    // 流水线阶段3: 输出映射
    reg [WIDTH-1:0] counter_stage3;
    reg valid_stage3;
    
    // 阶段1: 计数器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= enable;
            if (enable) begin
                counter_stage1 <= counter_stage1 + 1;
            end
        end
    end
    
    // 阶段2: 可以添加额外处理，这里只是传递数据
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 输出映射
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            counter_stage3 <= counter_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign wave_out = counter_stage3;
    assign valid = valid_stage3;
    
endmodule