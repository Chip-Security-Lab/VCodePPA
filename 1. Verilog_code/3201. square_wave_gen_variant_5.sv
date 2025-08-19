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
    reg [COUNTER_WIDTH-1:0] period_reg;
    wire period_reached;
    
    // 使用比较器优化：直接比较并避免减法运算
    assign period_reached = (counter >= period_reg);
    
    // 注册period输入以改善时序
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_reg <= {COUNTER_WIDTH{1'b0}};
        end else begin
            period_reg <= period;
        end
    end
    
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