//SystemVerilog
module pwm_codec #(
    parameter RES = 10
)(
    input                 clk,
    input                 rst,
    input      [RES-1:0]  duty,
    output reg            pwm_out
);

    // 计数器寄存器
    reg [RES-1:0] cnt_r;
    
    // 管道寄存器 - 将duty值缓存以减少时序路径
    reg [RES-1:0] duty_r;
    
    // 比较结果寄存器
    reg           compare_result;
    
    // 计数器逻辑 - 仅负责递增计数器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_r <= {RES{1'b0}};
        end else begin
            cnt_r <= cnt_r + 1'b1;
        end
    end
    
    // 输入缓存逻辑 - 仅负责捕获duty输入值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            duty_r <= {RES{1'b0}};
        end else begin
            duty_r <= duty; // 将输入duty值寄存一级减少关键路径
        end
    end
    
    // 比较逻辑 - 仅负责计数器与占空比的比较
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            compare_result <= 1'b0;
        end else begin
            compare_result <= (cnt_r < duty_r);
        end
    end
    
    // 输出寄存器逻辑 - 仅负责将比较结果输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= compare_result;
        end
    end

endmodule