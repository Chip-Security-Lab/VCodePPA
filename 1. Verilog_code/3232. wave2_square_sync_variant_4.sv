//SystemVerilog
module wave2_square_sync #(
    parameter PERIOD = 8,
    parameter SYNC_RESET = 1
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    localparam CNT_WIDTH = $clog2(PERIOD);
    reg [CNT_WIDTH-1:0] cnt;
    wire cnt_max;
    
    // 使用组合逻辑判断计数器是否达到最大值，减少比较器延迟
    assign cnt_max = (cnt == PERIOD-1);
    
    generate
        if (SYNC_RESET) begin
            always @(posedge clk) begin
                if (rst) begin
                    cnt <= '0;
                    wave_out <= 1'b0;
                end else begin
                    cnt <= cnt_max ? '0 : cnt + 1'b1;
                    wave_out <= cnt_max ? ~wave_out : wave_out;
                end
            end
        end else begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt <= '0;
                    wave_out <= 1'b0;
                end else begin
                    cnt <= cnt_max ? '0 : cnt + 1'b1;
                    wave_out <= cnt_max ? ~wave_out : wave_out;
                end
            end
        end
    endgenerate
endmodule