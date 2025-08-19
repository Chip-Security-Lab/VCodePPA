//SystemVerilog
module hamming_onehot_sm(
    input clk, rst, start,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg done
);
    // 使用独热码编码状态，简化状态机逻辑
    localparam S_IDLE = 4'b0001, 
               S_CALC = 4'b0010, 
               S_WRITE = 4'b0100, 
               S_DONE = 4'b1000;
    
    reg [3:0] state, next_state;
    
    // 状态转移逻辑 - 使用扁平化if-else结构
    always @(*) begin
        next_state = state; // 默认保持当前状态
        
        if (state == S_IDLE && start) 
            next_state = S_CALC;
        else if (state == S_CALC) 
            next_state = S_WRITE;
        else if (state == S_WRITE) 
            next_state = S_DONE;
        else if (state == S_DONE) 
            next_state = S_IDLE;
    end
    
    // 状态寄存器更新与输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            encoded <= 7'b0;
            done <= 1'b0;
        end 
        else begin
            state <= next_state;
            
            // 扁平化的输出逻辑
            if (state == S_CALC) begin
                encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
                encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
                encoded[2] <= data_in[0];
                encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
                encoded[4] <= data_in[1];
                encoded[5] <= data_in[2];
                encoded[6] <= data_in[3];
            end
            
            if (state == S_DONE)
                done <= 1'b1;
            else if (state == S_IDLE)
                done <= 1'b0;
        end
    end
endmodule