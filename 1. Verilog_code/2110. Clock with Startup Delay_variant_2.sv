//SystemVerilog
module clk_with_delay(
    input clk_in,
    input rst_n,
    input [3:0] delay_cycles,
    output reg clk_out
);
    reg [3:0] counter;
    reg running;
    wire delay_satisfied;
    
    // 简化逻辑：使用组合逻辑代替sequential逻辑判断delay_satisfied
    assign delay_satisfied = !running && (counter >= delay_cycles);
    
    // 整合counter逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
        end else if (!running) begin
            counter <= (counter >= delay_cycles) ? 4'd0 : (counter + 4'd1);
        end
    end
    
    // 状态和输出控制逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            running <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // 使用阻塞赋值顺序逻辑优化状态转换
            if (delay_satisfied)
                running <= 1'b1;
                
            // 只有running状态才翻转时钟
            clk_out <= running ? ~clk_out : clk_out;
        end
    end
endmodule