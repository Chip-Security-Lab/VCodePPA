//SystemVerilog
module wave9_pwm #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] duty,
    output wire             pwm_out
);
    // 流水线寄存器和控制信号
    reg [WIDTH-1:0] cnt_stage1;
    reg [WIDTH-1:0] duty_stage1, duty_stage2;
    reg             valid_stage1, valid_stage2, valid_stage3;
    reg             compare_result_stage2, compare_result_stage3;
    
    // 第一级流水线 - 计数器逻辑和输入寄存
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt_stage1 <= {WIDTH{1'b0}};
            duty_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            cnt_stage1 <= cnt_stage1 + 1'b1;
            duty_stage1 <= duty;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线 - 比较准备和信号传递
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            duty_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            compare_result_stage2 <= 1'b0;
        end else begin
            duty_stage2 <= duty_stage1;
            valid_stage2 <= valid_stage1;
            // 将比较操作分成两级，这一级只进行部分比较
            compare_result_stage2 <= (cnt_stage1[WIDTH-1:WIDTH/2] < duty_stage1[WIDTH-1:WIDTH/2]) || 
                                    ((cnt_stage1[WIDTH-1:WIDTH/2] == duty_stage1[WIDTH-1:WIDTH/2]) && 
                                     (cnt_stage1[WIDTH/2-1:0] < duty_stage1[WIDTH/2-1:0]));
        end
    end
    
    // 第三级流水线 - 最终比较和输出准备
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            valid_stage3 <= 1'b0;
            compare_result_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            // 在这一级确认最终的PWM输出状态
            compare_result_stage3 <= valid_stage2 ? compare_result_stage2 : compare_result_stage3;
        end
    end
    
    // 输出赋值
    assign pwm_out = valid_stage3 ? compare_result_stage3 : 1'b0;
    
endmodule