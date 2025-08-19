module wave2_square_sync #(
    parameter PERIOD = 8,
    parameter SYNC_RESET = 1
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    reg [$clog2(PERIOD)-1:0] cnt;

    generate
        if (SYNC_RESET) begin
            always @(posedge clk) begin
                if (rst) begin
                    cnt      <= 0;
                    wave_out <= 0;
                end else begin
                    if (cnt == PERIOD-1) begin
                        cnt      <= 0;
                        wave_out <= ~wave_out;
                    end else cnt <= cnt + 1;
                end
            end
        end else begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt      <= 0;
                    wave_out <= 0;
                end else begin
                    if (cnt == PERIOD-1) begin
                        cnt      <= 0;
                        wave_out <= ~wave_out;
                    end else cnt <= cnt + 1;
                end
            end
        end
    endgenerate
endmodule
