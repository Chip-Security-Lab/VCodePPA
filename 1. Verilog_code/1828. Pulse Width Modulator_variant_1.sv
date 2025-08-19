//SystemVerilog
module pwm_generator #(
    parameter CNT_WIDTH = 8
) (
    input  wire                 clock,
    input  wire                 reset_n,
    input  wire [CNT_WIDTH-1:0] duty_cycle,
    input  wire                 valid_in,
    output wire                 ready_out,
    output reg                  pwm_out
);
    // 流水线寄存器和控制信号
    reg [CNT_WIDTH-1:0] counter;
    reg [CNT_WIDTH-1:0] duty_cycle_stage1;
    reg [CNT_WIDTH-1:0] duty_cycle_stage2;
    reg                 valid_stage1;
    reg                 valid_stage2;
    reg                 comparison_result;
    
    // 流水线阶段1：计数器递增和保存输入参数
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            duty_cycle_stage1 <= {CNT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            duty_cycle_stage1 <= duty_cycle;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2：执行比较操作
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            comparison_result <= 1'b0;
            duty_cycle_stage2 <= {CNT_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            comparison_result <= (counter < duty_cycle_stage1);
            duty_cycle_stage2 <= duty_cycle_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3：输出生成
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pwm_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                pwm_out <= comparison_result;
            end
        end
    end
    
    // 反压控制信号
    assign ready_out = 1'b1; // 由于PWM连续工作，始终可以接收新数据
    
endmodule