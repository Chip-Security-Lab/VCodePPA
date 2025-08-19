//SystemVerilog
module wave6_sawtooth #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,  // 新增输入信号来控制流水线
    output wire [WIDTH-1:0] wave_out
);
    // 流水线阶段1：计算下一个值
    reg [WIDTH-1:0] counter_stage1;
    reg             valid_stage1;
    
    // 流水线阶段2：存储结果
    reg [WIDTH-1:0] counter_stage2;
    reg             valid_stage2;
    
    // 阶段1：计算递增值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (enable) begin
            counter_stage1 <= (counter_stage2 == {WIDTH{1'b1}}) ? 0 : counter_stage2 + 1;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2：输出值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign wave_out = counter_stage2;
    
endmodule