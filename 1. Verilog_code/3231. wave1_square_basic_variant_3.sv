//SystemVerilog
module wave1_square_basic #(
    parameter PERIOD = 10
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    reg [$clog2(PERIOD)-1:0] cnt;
    wire cnt_reset = (cnt == PERIOD-1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt      <= 0;
            wave_out <= 0;
        end else begin
            cnt <= cnt_reset ? '0 : (cnt + 1'b1);
            if (cnt_reset) begin
                wave_out <= ~wave_out;
            end
        end
    end
endmodule