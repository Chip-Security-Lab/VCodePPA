//SystemVerilog
module TimeoutMatcher #(parameter WIDTH=8, TIMEOUT=100) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg timeout
);
    reg [15:0] counter;
    wire [15:0] counter_next;
    wire [15:0] timeout_threshold;
    wire data_match;
    wire borrow;
    
    // 使用借位减法器实现计数器逻辑
    assign data_match = (data == pattern);
    assign timeout_threshold = TIMEOUT;
    
    // 借位减法器算法实现
    // 当数据匹配时，counter归零
    // 当数据不匹配时，使用借位减法器进行(counter + 1)计算
    assign {borrow, counter_next} = data_match ? 16'b0 : 
                                    (counter + 1'b1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'b0;
            timeout <= 1'b0;
        end else begin
            counter <= counter_next;
            // 使用借位比较器判断是否超时
            timeout <= (counter_next >= timeout_threshold) ? 1'b1 : 1'b0;
        end
    end
endmodule