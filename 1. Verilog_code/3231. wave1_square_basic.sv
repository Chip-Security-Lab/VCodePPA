module wave1_square_basic #(
    parameter PERIOD = 10
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    reg [$clog2(PERIOD)-1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt      <= 0;
            wave_out <= 0;
        end else begin
            if (cnt == PERIOD-1) begin
                cnt      <= 0;
                wave_out <= ~wave_out;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
