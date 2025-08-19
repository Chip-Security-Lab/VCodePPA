//SystemVerilog
module Timer_AutoReload #(parameter VAL=255) (
    input clk, en, rst,
    output reg alarm
);
    reg [7:0] cnt;
    wire [7:0] next_cnt;
    wire [7:0] inverted_one;
    wire [7:0] sum;
    wire carry;
    
    // 条件求和减法实现 (cnt - 1)
    // 对1取反加1实现补码
    assign inverted_one = 8'hFF;  // ~8'd1
    assign {carry, sum} = cnt + inverted_one + 8'd1;
    
    // 计算下一个计数值
    assign next_cnt = (cnt == 0) ? VAL : sum;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= VAL;
            alarm <= 0;
        end else if (en) begin
            alarm <= (cnt == 0);
            cnt <= next_cnt;
        end
    end
endmodule