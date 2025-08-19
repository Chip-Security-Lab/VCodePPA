//SystemVerilog
module rotate_left_shifter (
    input wire clk,
    input wire rst,
    input wire req,         // 请求信号，替代原来的enable
    output reg ack,         // 应答信号，新增
    output reg [7:0] data_out
);
    // 定义常量以提高可读性并降低功耗
    localparam INIT_PATTERN = 8'b10101010;
    
    // 状态定义
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    
    // 状态寄存器
    reg state;
    reg req_r; // 缓存请求信号以检测边沿
    
    // 使用异步复位以降低延迟并提高可靠性
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= INIT_PATTERN;
            ack <= 1'b0;
            state <= IDLE;
            req_r <= 1'b0;
        end
        else begin
            req_r <= req;
            
            case (state)
                IDLE: begin
                    if (req && !req_r) begin  // 检测req上升沿
                        // 进行数据旋转
                        data_out <= {data_out[6:0], data_out[7]};
                        ack <= 1'b1;          // 发送应答信号
                        state <= BUSY;
                    end
                end
                
                BUSY: begin
                    if (!req) begin           // req撤销后返回IDLE状态
                        ack <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule