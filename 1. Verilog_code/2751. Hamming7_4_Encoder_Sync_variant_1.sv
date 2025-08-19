//SystemVerilog
module Hamming7_4_Encoder_Sync (
    input clk,            // 系统时钟
    input rst_n,          // 异步低复位
    input [3:0] data_in,  // 4位输入数据
    input valid_in,       // 输入数据有效信号
    output ready_out,     // 输出就绪信号
    output reg [6:0] code_out, // 7位编码输出
    output reg valid_out, // 输出数据有效信号
    input ready_in        // 接收方就绪信号
);

// 状态定义
localparam IDLE = 2'b00;
localparam ENCODE = 2'b01;
localparam WAIT_READY = 2'b10;

// 状态寄存器和数据缓存
reg [1:0] state, next_state;
reg [3:0] data_buffer;
reg compute_done;

// 就绪信号产生逻辑
assign ready_out = (state == IDLE);

// 状态转换逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 下一状态逻辑
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (valid_in && ready_out) begin
                next_state = ENCODE;
            end
        end
        
        ENCODE: begin
            next_state = WAIT_READY;
        end
        
        WAIT_READY: begin
            if (ready_in && valid_out) begin
                next_state = IDLE;
            end
        end
        
        default: next_state = IDLE;
    endcase
end

// 数据缓存逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_buffer <= 4'b0;
        compute_done <= 1'b0;
    end else if (state == IDLE && valid_in && ready_out) begin
        data_buffer <= data_in;
        compute_done <= 1'b0;
    end else if (state == ENCODE) begin
        compute_done <= 1'b1;
    end
end

// 编码逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        code_out <= 7'b0;
        valid_out <= 1'b0;
    end else if (state == ENCODE) begin
        code_out[6:4] <= data_buffer[3:1];
        code_out[3]   <= data_buffer[3] ^ data_buffer[2] ^ data_buffer[0];
        code_out[2]   <= data_buffer[3] ^ data_buffer[1] ^ data_buffer[0];
        code_out[1]   <= data_buffer[2] ^ data_buffer[1] ^ data_buffer[0];
        code_out[0]   <= data_buffer[0];
        valid_out <= 1'b1;
    end else if (state == WAIT_READY && ready_in && valid_out) begin
        valid_out <= 1'b0;
    end
end

endmodule