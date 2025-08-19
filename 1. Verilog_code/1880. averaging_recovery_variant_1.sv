//SystemVerilog
module averaging_recovery #(
    parameter WIDTH = 8,
    parameter AVG_DEPTH = 4
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] noisy_in,
    input wire sample_en,
    output reg [WIDTH-1:0] filtered_out
);
    reg [WIDTH-1:0] samples [0:AVG_DEPTH-1];
    reg [WIDTH+2:0] sum;
    reg [1:0] state;
    integer i;
    
    // 状态定义
    localparam IDLE = 2'b00,
               SHIFT = 2'b01,
               SUM = 2'b10,
               AVERAGE = 2'b11;
    
    // 控制信号
    wire [1:0] ctrl = {rst, sample_en};
    
    always @(posedge clk) begin
        case (ctrl)
            2'b10, 2'b11: begin // 复位优先
                for (i = 0; i < AVG_DEPTH; i = i + 1)
                    samples[i] <= 0;
                sum <= 0;
                filtered_out <= 0;
                state <= IDLE;
            end
            
            2'b01: begin // 采样使能且非复位
                case (state)
                    IDLE: begin
                        // 初始化
                        state <= SHIFT;
                    end
                    
                    SHIFT: begin
                        // 移位新样本
                        for (i = AVG_DEPTH-1; i > 0; i = i - 1)
                            samples[i] <= samples[i-1];
                        samples[0] <= noisy_in;
                        sum <= 0; // 重置和
                        state <= SUM;
                    end
                    
                    SUM: begin
                        // 计算和
                        for (i = 0; i < AVG_DEPTH; i = i + 1)
                            sum <= sum + samples[i];
                        state <= AVERAGE;
                    end
                    
                    AVERAGE: begin
                        // 计算平均值
                        filtered_out <= sum / AVG_DEPTH;
                        state <= IDLE;
                    end
                endcase
            end
            
            default: begin // 保持当前状态
                // 无操作
            end
        endcase
    end
endmodule