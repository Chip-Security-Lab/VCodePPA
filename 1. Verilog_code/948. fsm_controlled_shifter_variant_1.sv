//SystemVerilog
module fsm_controlled_shifter (
    input clk, rst, start,
    input [31:0] data,
    input [4:0] total_shift,
    output reg done,
    output reg [31:0] result
);
    // 用参数定义状态常量
    localparam IDLE = 1'b0;
    localparam SHIFT = 1'b1;

    reg state; // 状态寄存器
    reg [4:0] cnt;
    
    // 优化比较逻辑和状态转换
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cnt <= 5'b0;
            result <= 32'b0;
            done <= 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    if (start) begin
                        result <= data;
                        cnt <= total_shift;
                        // 优化：直接判断是否需要进入SHIFT状态
                        if (|total_shift) begin
                            state <= SHIFT;
                            done <= 1'b0;
                        end else begin
                            // 如果不需要移位，直接完成
                            done <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end
                
                SHIFT: begin
                    // 优化：使用并行比较器检查计数
                    if (cnt == 5'd1) begin
                        // 最后一次移位
                        result <= result << 1;
                        done <= 1'b1;
                        state <= IDLE;
                        cnt <= 5'd0;
                    end else begin
                        // 执行移位并递减计数器
                        result <= result << 1;
                        cnt <= cnt - 5'd1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule