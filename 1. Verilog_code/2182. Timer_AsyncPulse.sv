module Timer_AsyncPulse (
    input clk, rst, start,
    output pulse
);
    reg [3:0] cnt;
    assign pulse = (cnt == 4'd15);
    always @(posedge clk or posedge rst) begin
        if (rst) cnt <= 0;
        else if (start) cnt <= cnt + (cnt < 15);
    end
endmodule