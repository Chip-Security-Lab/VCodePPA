//SystemVerilog
module hamming_onehot_sm(
    input clk, rst, start,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg done
);
    reg [3:0] state, next_state;
    reg [3:0] data_buf1, data_buf2;
    reg [6:0] encoded_next;
    
    parameter S_IDLE = 4'b0001, S_CALC = 4'b0010, S_WRITE = 4'b0100, S_DONE = 4'b1000;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            data_buf1 <= 4'b0;
            data_buf2 <= 4'b0;
            encoded <= 7'b0;
            done <= 1'b0;
        end else begin
            state <= next_state;
            data_buf1 <= data_in;
            data_buf2 <= data_buf1;
            encoded <= encoded_next;
            done <= (state == S_DONE);
        end
    end
    
    always @(*) begin
        next_state = state;
        if (state == S_IDLE && start) next_state = S_CALC;
        else if (state == S_CALC) next_state = S_WRITE;
        else if (state == S_WRITE) next_state = S_DONE;
        else if (state == S_DONE) next_state = S_IDLE;
        else next_state = S_IDLE;
    end
    
    always @(*) begin
        encoded_next = encoded;
        if (state == S_CALC) begin
            encoded_next[0] = data_buf1[0] ^ data_buf1[1] ^ data_buf2[3];
            encoded_next[1] = data_buf1[0] ^ data_buf2[2] ^ data_buf2[3];
            encoded_next[2] = data_buf1[0];
            encoded_next[3] = data_buf1[1] ^ data_buf2[2] ^ data_buf1[3];
            encoded_next[4] = data_buf1[1];
            encoded_next[5] = data_buf2[2];
            encoded_next[6] = data_buf2[3];
        end
    end
endmodule