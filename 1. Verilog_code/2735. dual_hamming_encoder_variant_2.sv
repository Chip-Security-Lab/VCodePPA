//SystemVerilog
module dual_hamming_encoder(
    input clk, rst_n,
    input [3:0] data_a, data_b,
    input data_valid,  // 输入数据有效信号
    output data_ready, // 输出准备接收数据信号
    output reg [6:0] encoded_a, encoded_b,
    output reg encoded_valid, // 输出数据有效信号
    input encoded_ready  // 输入准备接收编码数据信号
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam ENCODE = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] data_a_reg, data_b_reg;
    reg [6:0] encoded_a_next, encoded_b_next;
    
    // 状态机和数据存储逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_a_reg <= 4'b0;
            data_b_reg <= 4'b0;
            encoded_a <= 7'b0;
            encoded_b <= 7'b0;
            encoded_valid <= 1'b0;
        end else begin
            state <= next_state;
            
            if (state == IDLE && data_valid && data_ready) begin
                data_a_reg <= data_a;
                data_b_reg <= data_b;
            end
            
            if (state == ENCODE) begin
                encoded_a <= encoded_a_next;
                encoded_b <= encoded_b_next;
                encoded_valid <= 1'b1;
            end else if (state == WAIT_ACK && encoded_ready) begin
                encoded_valid <= 1'b0;
            end
        end
    end
    
    // 组合逻辑-状态转换
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (data_valid && data_ready)
                    next_state = ENCODE;
            end
            
            ENCODE: begin
                next_state = WAIT_ACK;
            end
            
            WAIT_ACK: begin
                if (encoded_ready)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 组合逻辑-编码计算
    always @(*) begin
        // Channel A encoding
        encoded_a_next[0] = data_a_reg[0] ^ data_a_reg[1] ^ data_a_reg[3];
        encoded_a_next[1] = data_a_reg[0] ^ data_a_reg[2] ^ data_a_reg[3];
        encoded_a_next[2] = data_a_reg[0];
        encoded_a_next[3] = data_a_reg[1] ^ data_a_reg[2] ^ data_a_reg[3];
        encoded_a_next[4] = data_a_reg[1];
        encoded_a_next[5] = data_a_reg[2];
        encoded_a_next[6] = data_a_reg[3];
        
        // Channel B encoding
        encoded_b_next[0] = data_b_reg[0] ^ data_b_reg[1] ^ data_b_reg[3];
        encoded_b_next[1] = data_b_reg[0] ^ data_b_reg[2] ^ data_b_reg[3];
        encoded_b_next[2] = data_b_reg[0];
        encoded_b_next[3] = data_b_reg[1] ^ data_b_reg[2] ^ data_b_reg[3];
        encoded_b_next[4] = data_b_reg[1];
        encoded_b_next[5] = data_b_reg[2];
        encoded_b_next[6] = data_b_reg[3];
    end
    
    // 生成ready信号
    assign data_ready = (state == IDLE);
    
endmodule