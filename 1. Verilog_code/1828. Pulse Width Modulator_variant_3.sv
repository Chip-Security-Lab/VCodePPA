//SystemVerilog
module pwm_generator #(
    parameter CNT_WIDTH = 8
) (
    input  wire                 clock,
    input  wire                 reset_n,
    input  wire [CNT_WIDTH-1:0] duty_cycle,
    output reg                  pwm_out
);
    reg [CNT_WIDTH-1:0] counter;
    // 新增比较结果寄存器，用于后向重定时
    reg compare_result;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            compare_result <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            // 将比较逻辑结果寄存到compare_result中
            compare_result <= (counter < duty_cycle);
        end
    end
    
    // 将输出寄存器移到单独的always块，使用预先计算的比较结果
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= compare_result;
        end
    end
endmodule