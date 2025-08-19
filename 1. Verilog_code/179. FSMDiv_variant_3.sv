//SystemVerilog
module FSMDiv(
    input clk, start,
    input [15:0] dividend, divisor,
    output reg [15:0] quotient,
    output done
);
    reg [1:0] state;
    reg [15:0] rem;
    reg [4:0] cnt;
    
    // 桶形移位器结构的实现
    wire [15:0] shifted_rem;
    
    // 单位移位结果
    wire [15:0] rem_sll_1 = {rem[14:0], 1'b0};
    
    // 桶形移位器多路复用器实现
    assign shifted_rem = rem_sll_1;
    
    // 比较器和减法器实现
    wire [15:0] sub_result = shifted_rem - divisor;
    wire compare_result = (shifted_rem >= divisor);
    
    always @(posedge clk) begin
        case(state)
            2'b00: begin
                if(start) begin
                    rem <= dividend;
                    quotient <= 16'b0; // 显式初始化
                    cnt <= 5'd15;
                    state <= 2'b01;
                end
            end
            
            2'b01: begin
                // 使用桶形移位器的结果
                rem <= compare_result ? sub_result : shifted_rem;
                
                // 使用条件赋值更新商
                if(compare_result)
                    quotient[cnt] <= 1'b1;
                
                cnt <= cnt - 5'd1;
                
                if(cnt == 5'd0)
                    state <= 2'b10;
            end
            
            2'b10: begin
                state <= 2'b00;
            end
            
            default: begin
                state <= 2'b00;
            end
        endcase
    end
    
    // 完成信号
    assign done = (state == 2'b10);
    
endmodule