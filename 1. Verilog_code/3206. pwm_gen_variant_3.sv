//SystemVerilog
module pwm_gen(
    input clk,
    input reset,
    input [7:0] duty,
    output reg pwm_out
);
    reg [7:0] counter;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= 8'h00;
            pwm_out <= 1'b0;
        end
        else begin
            counter <= counter + 1'b1;
            
            // 当counter归零时设置输出(counter将溢出到0)
            if (counter == 8'hFF)
                pwm_out <= (duty != 0); // 只有占空比不为0时置高
            // 当counter达到duty值时复位输出
            else if (counter == duty - 1'b1)
                pwm_out <= 1'b0;
        end
    end
endmodule