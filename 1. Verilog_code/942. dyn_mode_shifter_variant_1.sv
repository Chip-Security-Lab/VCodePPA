//SystemVerilog
module dyn_mode_shifter (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号，低电平有效
    
    // 输入接口（Valid-Ready协议）
    input wire [15:0] data_in,
    input wire [3:0] shift_in,
    input wire [1:0] mode_in, // 00-逻辑左 01-算术右 10-循环
    input wire valid_in,      // 输入数据有效信号
    output reg ready_in,      // 输入就绪信号
    
    // 输出接口（Valid-Ready协议）
    output reg [15:0] data_out,
    output reg valid_out,     // 输出数据有效信号
    input wire ready_out      // 输出就绪信号
);

    // 内部寄存器
    reg [15:0] data_r;
    reg [3:0] shift_r;
    reg [1:0] mode_r;
    reg computing;
    
    // 状态机状态
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] state, next_state;
    
    // 状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (valid_in && ready_in) 
                    next_state = COMPUTE;
            end
            
            COMPUTE: begin
                next_state = DONE;
            end
            
            DONE: begin
                if (valid_out && ready_out)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 输入数据寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r <= 16'b0;
            shift_r <= 4'b0;
            mode_r <= 2'b0;
        end else if (state == IDLE && valid_in && ready_in) begin
            data_r <= data_in;
            shift_r <= shift_in;
            mode_r <= mode_in;
        end
    end
    
    // 输入就绪信号
    always @(*) begin
        ready_in = (state == IDLE);
    end
    
    // 计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
        end else if (state == COMPUTE) begin
            case(mode_r)
                2'b00: data_out <= data_r << shift_r;
                2'b01: data_out <= $signed(data_r) >>> shift_r;
                2'b10: data_out <= (data_r << shift_r) | (data_r >> (16 - shift_r));
                default: data_out <= data_r;
            endcase
        end
    end
    
    // 输出有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else if (state == COMPUTE) begin
            valid_out <= 1'b1;
        end else if (state == DONE && ready_out) begin
            valid_out <= 1'b0;
        end
    end
    
endmodule