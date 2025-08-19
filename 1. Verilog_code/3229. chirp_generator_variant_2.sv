//SystemVerilog
module chirp_generator(
    input clk,
    input rst,
    input [15:0] start_freq,
    input [15:0] freq_step,
    input [7:0] step_interval,
    input valid_in,        // 新增：输入数据有效信号
    output reg ready_out,  // 新增：接收方准备好信号
    output reg [7:0] chirp_out,
    output reg valid_out   // 新增：输出数据有效信号
);
    reg [15:0] freq;
    reg [15:0] phase_acc;
    reg [7:0] interval_counter;
    reg processing;        // 新增：指示正在处理数据
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam OUTPUT_READY = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 状态转换逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: 
                if (valid_in && ready_out)
                    next_state = PROCESSING;
            PROCESSING:
                next_state = OUTPUT_READY;
            OUTPUT_READY:
                if (valid_out)
                    next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end
    
    // 控制信号和数据处理
    always @(posedge clk) begin
        if (rst) begin
            freq <= 16'd0;
            phase_acc <= 16'd0;
            interval_counter <= 8'd0;
            chirp_out <= 8'd128;
            ready_out <= 1'b1;   // 复位后准备好接收数据
            valid_out <= 1'b0;   // 复位后输出无效
            processing <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in && ready_out) begin
                        // 接收新数据
                        freq <= start_freq;
                        ready_out <= 1'b0;  // 不再接收数据
                        processing <= 1'b1;
                    end
                end
                
                PROCESSING: begin
                    // 更新相位累加器
                    phase_acc <= phase_acc + freq;
                    
                    // 正弦波近似计算
                    if (phase_acc[15:14] == 2'b00)
                        chirp_out <= 8'd128 + {1'b0, phase_acc[13:7]};
                    else if (phase_acc[15:14] == 2'b01)
                        chirp_out <= 8'd255 - {1'b0, phase_acc[13:7]};
                    else if (phase_acc[15:14] == 2'b10)
                        chirp_out <= 8'd127 - {1'b0, phase_acc[13:7]};
                    else
                        chirp_out <= 8'd0 + {1'b0, phase_acc[13:7]};
                        
                    // 频率步进逻辑
                    if (interval_counter >= step_interval) begin
                        interval_counter <= 8'd0;
                        freq <= freq + freq_step;
                    end else begin
                        interval_counter <= interval_counter + 8'd1;
                    end
                    
                    valid_out <= 1'b1;  // 输出有效
                end
                
                OUTPUT_READY: begin
                    valid_out <= 1'b0;   // 完成输出
                    ready_out <= 1'b1;   // 准备接收新数据
                    processing <= 1'b0;
                end
                
                default: begin
                    ready_out <= 1'b1;
                    valid_out <= 1'b0;
                    processing <= 1'b0;
                end
            endcase
        end
    end
endmodule