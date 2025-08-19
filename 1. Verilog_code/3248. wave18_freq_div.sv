module wave18_freq_div #(
    parameter DIV_FACTOR = 4
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    reg [$clog2(DIV_FACTOR)-1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt      <= 0;
            wave_out <= 0;
        end else begin
            if(cnt == DIV_FACTOR-1) begin
                cnt      <= 0;
                wave_out <= ~wave_out;
            end else
                cnt <= cnt + 1;
        end
    end
endmodule
