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
    reg [CNT_WIDTH-1:0] duty_cycle_reg;
    wire pwm_comb;
    
    // 将比较逻辑从always块中分离出来，变为组合逻辑
    assign pwm_comb = (counter < duty_cycle_reg) ? 1'b1 : 1'b0;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            duty_cycle_reg <= {CNT_WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            duty_cycle_reg <= duty_cycle; // 寄存duty_cycle输入
            pwm_out <= pwm_comb; // 将组合逻辑结果寄存到输出
        end
    end
endmodule