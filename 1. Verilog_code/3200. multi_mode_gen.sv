module multi_mode_gen #(
    parameter MODE_WIDTH = 2
)(
    input clk,
    input [MODE_WIDTH-1:0] mode,
    input [15:0] param,
    output reg signal_out
);
reg [15:0] counter;

always @(posedge clk) begin
    counter <= counter + 1;
    
    case(mode)
        2'b00: signal_out <= (counter < param);          // PWM模式
        2'b01: signal_out <= (counter == 16'd0);         // 单脉冲模式
        2'b10: signal_out <= counter[param[3:0]];        // 分频模式
        2'b11: signal_out <= ^counter[15:8];             // 随机模式
    endcase
end
endmodule

