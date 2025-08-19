//SystemVerilog
module wave1_square_basic #(
    parameter PERIOD = 10
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    localparam CNT_WIDTH = $clog2(PERIOD);
    reg [CNT_WIDTH-1:0] cnt;
    
    // 优化比较逻辑：使用更高效的阈值比较方式
    wire period_reached = (cnt >= PERIOD-1);
    
    // 使用单个缓冲寄存器以减少资源使用
    reg period_flag;
    
    // 合并计数器和标志逻辑，减少always块数量
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            period_flag <= 0;
        end else begin
            // 优化判断逻辑，避免额外的比较器
            if (cnt == PERIOD-1) begin
                cnt <= 0;
                period_flag <= 1;
            end else begin
                cnt <= cnt + 1'b1;
                period_flag <= 0;
            end
        end
    end
    
    // 优化波形输出逻辑，使用period_flag作为触发条件
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wave_out <= 0;
        end else if (period_flag) begin
            wave_out <= ~wave_out;
        end
    end
endmodule