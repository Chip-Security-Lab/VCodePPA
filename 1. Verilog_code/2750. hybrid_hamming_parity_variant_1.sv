//SystemVerilog
module hybrid_hamming_parity(
    input clk, rst_n,
    input [7:0] data,
    input valid,      // 发送方指示数据有效的信号
    output reg ready, // 接收方指示准备好接收数据的信号
    output reg [15:0] encoded,
    output reg encoded_valid // 输出数据有效信号
);
    reg [11:0] hamming_code;
    reg [3:0] parity_bits;
    wire [3:0] data_low = data[3:0];
    wire [3:0] data_high = data[7:4];
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam DATA_READY = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] data_reg; // 寄存输入数据
    
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
                if (valid && ready)
                    next_state = PROCESSING;
            end
            PROCESSING: begin
                next_state = DATA_READY;
            end
            DATA_READY: begin
                if (encoded_valid)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 主处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hamming_code <= 12'b0;
            parity_bits <= 4'b0;
            encoded <= 16'b0;
            ready <= 1'b1;
            encoded_valid <= 1'b0;
            data_reg <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    encoded_valid <= 1'b0;
                    ready <= 1'b1;
                    if (valid && ready) begin
                        data_reg <= data;
                        ready <= 1'b0;
                    end
                end
                
                PROCESSING: begin
                    // Optimized Hamming code generation
                    hamming_code[0] <= ^{data_reg[0], data_reg[1], data_reg[3]};
                    hamming_code[1] <= ^{data_reg[0], data_reg[2], data_reg[3]};
                    hamming_code[2] <= data_reg[0];
                    hamming_code[3] <= ^{data_reg[1], data_reg[2], data_reg[3]};
                    hamming_code[4] <= data_reg[1];
                    hamming_code[5] <= data_reg[2];
                    hamming_code[6] <= data_reg[3];
                    
                    // Optimized parity generation
                    parity_bits[0] <= ^data_reg[7:4];
                    parity_bits[1] <= ^{data_reg[7], data_reg[6]};
                    parity_bits[2] <= ^{data_reg[5], data_reg[4]};
                    parity_bits[3] <= ^data_reg[7:4];
                end
                
                DATA_READY: begin
                    // Optimized output combination
                    encoded <= {data_reg[7:4], parity_bits, hamming_code[6:0]};
                    encoded_valid <= 1'b1;
                    ready <= 1'b1;
                end
            endcase
        end
    end
endmodule