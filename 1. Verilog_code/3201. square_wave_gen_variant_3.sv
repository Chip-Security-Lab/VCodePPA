//SystemVerilog
module square_wave_gen #(
    parameter COUNTER_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] period,
    output reg out
);
    reg [COUNTER_WIDTH-1:0] counter;
    wire [COUNTER_WIDTH-1:0] period_minus_1;
    wire period_reached;
    
    // 预计算period-1,避免在比较时进行减法运算
    assign period_minus_1 = period - 1'b1;
    
    // 使用异或比较优化相等判断
    assign period_reached = ~|(counter ^ period_minus_1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            out <= 1'b0;
        end else begin
            if (period_reached) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                out <= ~out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule