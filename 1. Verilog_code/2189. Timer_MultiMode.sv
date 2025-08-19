module Timer_MultiMode #(parameter MODE=0) (
    input clk, rst_n,
    input [7:0] period,
    output reg out
);
    reg [7:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 0;
        else cnt <= cnt + 1;
        case(MODE)
            0: out <= (cnt == period);        // 单次触发
            1: out <= (cnt >= period);        // 持续高电平
            2: out <= (cnt[3:0] == period[3:0]);  // 分频模式
        endcase
    end
endmodule