//SystemVerilog
module debounced_reset #(
    parameter DEBOUNCE_COUNT = 3
)(
    input wire clk,
    input wire noisy_reset,
    output reg clean_reset
);
    reg [1:0] count;
    reg reset_ff;
    
    // 状态标志位
    wire state = (reset_ff != noisy_reset) ? 2'b00 : 
                 (count < DEBOUNCE_COUNT) ? 2'b01 : 2'b10;
                 
    always @(posedge clk) begin
        reset_ff <= noisy_reset;
        
        case (state)
            2'b00: begin // 输入信号变化
                count <= 0;
            end
            2'b01: begin // 计数未达到稳定值
                count <= count + 1'b1;
            end
            2'b10: begin // 稳定状态
                clean_reset <= reset_ff;
            end
            default: begin // 默认情况
                count <= count;
            end
        endcase
    end
endmodule