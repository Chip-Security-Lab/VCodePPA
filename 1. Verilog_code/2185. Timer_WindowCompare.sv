module Timer_WindowCompare (
    input clk, rst_n, en,
    input [7:0] low_th, high_th,
    output reg in_window
);
    reg [7:0] timer;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 0;
            in_window <= 0;
        end else if (en) begin
            timer <= timer + 1;
            in_window <= (timer >= low_th) && (timer <= high_th);
        end
    end
endmodule