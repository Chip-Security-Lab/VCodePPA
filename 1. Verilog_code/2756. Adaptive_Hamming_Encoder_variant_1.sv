//SystemVerilog
module Adaptive_Hamming_Encoder(
    input clk,
    input rst_n,                 // 复位信号
    input [7:0] data_in,         // 输入数据
    input valid_in,              // 数据有效信号
    output ready_out,            // 接收就绪信号
    
    output reg [11:0] adaptive_code,    // 编码后的数据
    output reg [2:0] parity_bits_used,  // 使用的奇偶校验位数量
    output reg valid_out,               // 输出数据有效信号
    input ready_in                      // 下游模块就绪信号
);
    // 内部状态定义
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam WAITING = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] data_reg;
    
    // 扇出缓冲: 状态缓冲寄存器
    reg [1:0] state_buf1, state_buf2;
    
    // 扇出缓冲: 数据寄存器缓冲
    reg [7:0] data_reg_buf1, data_reg_buf2;
    
    // 多级ready_out缓冲
    wire ready_out_int;
    reg ready_out_buf1, ready_out_buf2;
    
    // 替换$countones函数
    function [2:0] count_ones;
        input [7:0] data;
        reg [2:0] count;
        integer i;
        begin
            count = 0;
            for(i=0; i<8; i=i+1)
                if(data[i]) count = count + 1;
            count_ones = count;
        end
    endfunction
    
    // 扇出缓冲: count_ones函数输出缓冲
    reg [2:0] count_reg;
    reg [2:0] count_buf1, count_buf2;
    
    // 当前处于IDLE状态且没有正在处理的数据时，接收新数据
    assign ready_out_int = (state == IDLE);
    
    // ready_out多级缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_out_buf1 <= 1'b0;
            ready_out_buf2 <= 1'b0;
        end else begin
            ready_out_buf1 <= ready_out_int;
            ready_out_buf2 <= ready_out_buf1;
        end
    end
    
    assign ready_out = ready_out_buf2;
    
    // 状态缓冲寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_buf1 <= IDLE;
            state_buf2 <= IDLE;
        end else begin
            state_buf1 <= state;
            state_buf2 <= state_buf1;
        end
    end
    
    // 数据寄存器缓冲更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_buf1 <= 8'b0;
            data_reg_buf2 <= 8'b0;
        end else begin
            data_reg_buf1 <= data_reg;
            data_reg_buf2 <= data_reg_buf1;
        end
    end
    
    // count_ones缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 3'b0;
            count_buf1 <= 3'b0;
            count_buf2 <= 3'b0;
        end else if (state == PROCESSING) begin
            count_reg <= count_ones(data_reg);
            count_buf1 <= count_reg;
            count_buf2 <= count_buf1;
        end
    end
    
    // adaptive_code缓冲寄存器
    reg [11:0] adaptive_code_buf1, adaptive_code_buf2;
    
    // 状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid_out <= 1'b0;
            data_reg <= 8'b0;
            adaptive_code <= 12'b0;
            parity_bits_used <= 3'b0;
            adaptive_code_buf1 <= 12'b0;
            adaptive_code_buf2 <= 12'b0;
        end else begin
            case(state)
                IDLE: begin
                    if (valid_in && ready_out_int) begin
                        // 捕获输入数据
                        data_reg <= data_in;
                        state <= PROCESSING;
                        valid_out <= 1'b0;
                    end
                end
                
                PROCESSING: begin
                    // 处理数据并生成输出
                    case(count_ones(data_reg))
                        3'd0, 3'd1, 3'd2: begin // 低密度使用(8,4)码
                            adaptive_code_buf1[10:8] <= data_reg[7:5];
                            adaptive_code_buf1[7] <= ^{data_reg[7:4], data_reg[3:0]};
                            adaptive_code_buf1[6:3] <= data_reg[3:0];
                            adaptive_code_buf1[2:0] <= 3'b0;
                            parity_bits_used <= 3'd4;
                        end
                        default: begin // 高密度使用(12,8)码
                            adaptive_code_buf1[11] <= ^data_reg;
                            adaptive_code_buf1[10:3] <= data_reg;
                            adaptive_code_buf1[2] <= ^{data_reg[7:5], data_reg[3:1]};
                            adaptive_code_buf1[1] <= ^{data_reg[4:2], data_reg[0]};
                            adaptive_code_buf1[0] <= ^{data_reg[7:4], data_reg[3:0]};
                            parity_bits_used <= 3'd3;
                        end
                    endcase
                    
                    // 缓冲adaptive_code的输出
                    adaptive_code_buf2 <= adaptive_code_buf1;
                    adaptive_code <= adaptive_code_buf2;
                    
                    valid_out <= 1'b1;
                    state <= WAITING;
                end
                
                WAITING: begin
                    // 等待下游接收数据
                    if (ready_in && valid_out) begin
                        valid_out <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule