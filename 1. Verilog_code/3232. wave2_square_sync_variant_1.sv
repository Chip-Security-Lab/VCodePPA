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
    
    // 使用预计算的比较结果，减少关键路径延迟
    assign cnt_max = (cnt == PERIOD-1);
    
    generate
        if (SYNC_RESET) begin
            always @(posedge clk) begin
                if (rst) begin
                    cnt <= {CNT_WIDTH{1'b0}};
                    wave_out <= 1'b0;
                end else begin
                    // 优化计数器逻辑，减少MUX结构
                    cnt <= cnt_max ? {CNT_WIDTH{1'b0}} : cnt + 1'b1;
                    
                    // 只在计数器到达最大值时才修改wave_out
                    if (cnt_max) begin
                        wave_out <= ~wave_out;
                    end
                end
            end
        end else begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt <= {CNT_WIDTH{1'b0}};
                    wave_out <= 1'b0;
                end else begin
                    // 优化计数器逻辑，减少MUX结构
                    cnt <= cnt_max ? {CNT_WIDTH{1'b0}} : cnt + 1'b1;
                    
                    // 只在计数器到达最大值时才修改wave_out
                    if (cnt_max) begin
                        wave_out <= ~wave_out;
                    end
                end
            end
        end
    endgenerate
endmodule