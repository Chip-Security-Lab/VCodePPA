//SystemVerilog
module wave9_pwm #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] duty,
    output reg              pwm_out
);
    // 计数器和比较结果寄存器
    reg [WIDTH-1:0] cnt_r;
    reg             compare_result_r;
    
    // 计数器逻辑 - 第一级流水线
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt_r <= {WIDTH{1'b0}};
        end else begin
            cnt_r <= cnt_r + 1'b1;
        end
    end
    
    // 比较逻辑 - 第二级流水线
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            compare_result_r <= 1'b0;
        end else begin
            compare_result_r <= (cnt_r < duty) ? 1'b1 : 1'b0;
        end
    end
    
    // 输出寄存器 - 第三级流水线
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= compare_result_r;
        end
    end
endmodule