//SystemVerilog
module priority_demux (
    input wire data_in,                  // Input data
    input wire [2:0] pri_select,         // Priority selection
    output reg [7:0] dout                // Output channels
);
    // 优化后的实现，使用case语句替代if-else链
    // 这可以改善时序和资源使用
    always @(*) begin
        dout = 8'b0;
        
        case (1'b1)
            pri_select[2]: dout[7:4] = {4{data_in}};
            pri_select[1]: dout[3:2] = {2{data_in}};
            pri_select[0]: dout[1] = data_in;
            default:       dout[0] = data_in;
        endcase
    end
endmodule

module booth_multiplier_8bit (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] multiplicand,  // 被乘数
    input wire [7:0] multiplier,    // 乘数
    output reg [15:0] product,      // 乘积结果
    output reg done                 // 乘法完成信号
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] counter;
    reg [16:0] acc;    // 累加器，包含product和额外位
    reg [7:0] m;       // 存储被乘数
    
    // 状态转移逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (counter == 4'd4) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            acc <= 17'd0;
            m <= 8'd0;
            product <= 16'd0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        counter <= 4'd0;
                        m <= multiplicand;
                        acc <= {8'd0, multiplier, 1'b0}; // 初始化累加器，最低位为额外位
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    case (acc[1:0])
                        2'b01: acc[16:9] <= acc[16:9] + m;        // +M
                        2'b10: acc[16:9] <= acc[16:9] - m;        // -M
                        default: ;                                 // 00 or 11: no operation
                    endcase
                    
                    // 算术右移
                    acc <= $signed(acc) >>> 2;
                    counter <= counter + 4'd1;
                end
                
                DONE: begin
                    product <= acc[16:1]; // 结果在acc[16:1]中
                    done <= 1'b1;
                end
                
                default: ;
            endcase
        end
    end
endmodule