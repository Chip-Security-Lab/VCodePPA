module Timer_AutoReload #(parameter VAL=255) (
    input clk, en, rst,
    output reg alarm
);
    reg [7:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= VAL;
            alarm <= 0;
        end else if (en) begin
            alarm <= (cnt == 0);
            cnt <= (cnt == 0) ? VAL : cnt - 1;
        end
    end
endmodule