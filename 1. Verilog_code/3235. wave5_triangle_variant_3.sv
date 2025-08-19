//SystemVerilog
module wave5_triangle #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // 第一级流水线 - 计算新值
    reg [WIDTH-1:0] value_stage1;
    reg direction_stage1;
    reg valid_stage1;
    
    // 第二级流水线 - 判断方向变化
    reg [WIDTH-1:0] value_stage2;
    reg direction_stage2;
    reg valid_stage2;
    reg direction_next_stage2;

    // 第一级流水线 - 计算新值
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            value_stage1 <= 0;
            direction_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if(direction_stage1)
                value_stage1 <= value_stage1 + 1'b1;
            else
                value_stage1 <= value_stage1 - 1'b1;
                
            // 反馈方向更新
            if(valid_stage2)
                direction_stage1 <= direction_next_stage2;
        end
    end

    // 第二级流水线 - 判断方向变化
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            value_stage2 <= 0;
            direction_stage2 <= 1'b1;
            direction_next_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            value_stage2 <= value_stage1;
            direction_stage2 <= direction_stage1;
            
            // 默认保持当前方向
            direction_next_stage2 <= direction_stage2;
            
            // 检查是否需要改变方向
            if(value_stage1 == {WIDTH{1'b1}})
                direction_next_stage2 <= 1'b0;
            else if(value_stage1 == 0)
                direction_next_stage2 <= 1'b1;
        end
    end

    // 输出赋值
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out <= 0;
        end else if(valid_stage2) begin
            wave_out <= value_stage2;
        end
    end
endmodule