//SystemVerilog
module CounterMatcher #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [15:0] match_count
);
    // 使用中间信号存储比较结果，降低关键路径延迟
    reg match_detected;
    
    // 比较逻辑与计数器更新分离
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_detected <= 1'b0;
            match_count <= 16'h0;
        end else begin
            // 将比较结果存储在寄存器中
            match_detected <= (data == pattern);
            // 基于上一个周期的比较结果更新计数器
            if (match_detected) 
                match_count <= match_count + 16'h1;
        end
    end
endmodule