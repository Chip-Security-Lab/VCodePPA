//SystemVerilog
module wave2_square_sync #(
    parameter PERIOD = 8,
    parameter SYNC_RESET = 1
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    // 使用精确的位宽以减少资源使用
    localparam CNT_WIDTH = $clog2(PERIOD);
    reg [CNT_WIDTH-1:0] cnt;
    
    // 预计算最大计数值，避免重复计算
    localparam [CNT_WIDTH-1:0] MAX_CNT = PERIOD - 1;
    
    // 下一个计数值的逻辑，与时钟沿无关的组合逻辑
    wire [CNT_WIDTH-1:0] next_cnt = (cnt == MAX_CNT) ? {CNT_WIDTH{1'b0}} : cnt + 1'b1;
    
    // 下一个波形输出的逻辑
    wire next_wave_out = (cnt == MAX_CNT) ? ~wave_out : wave_out;

    generate
        if (SYNC_RESET) begin
            always @(posedge clk) begin
                if (rst) begin
                    cnt <= {CNT_WIDTH{1'b0}};
                    wave_out <= 1'b0;
                end else begin
                    cnt <= next_cnt;
                    wave_out <= next_wave_out;
                end
            end
        end else begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt <= {CNT_WIDTH{1'b0}};
                    wave_out <= 1'b0;
                end else begin
                    cnt <= next_cnt;
                    wave_out <= next_wave_out;
                end
            end
        end
    endgenerate
endmodule