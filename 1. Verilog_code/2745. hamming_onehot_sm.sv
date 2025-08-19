module hamming_onehot_sm(
    input clk, rst, start,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg done
);
    reg [3:0] state;
    parameter S_IDLE = 4'b0001, S_CALC = 4'b0010, S_WRITE = 4'b0100, S_DONE = 4'b1000;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            encoded <= 7'b0;
            done <= 1'b0;
        end else case (state)
            S_IDLE: if (start) state <= S_CALC;
            S_CALC: begin
                encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
                encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
                encoded[2] <= data_in[0];
                encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
                encoded[4] <= data_in[1];
                encoded[5] <= data_in[2];
                encoded[6] <= data_in[3];
                state <= S_WRITE;
            end
            S_WRITE: begin state <= S_DONE; end
            S_DONE: begin done <= 1'b1; state <= S_IDLE; end
        endcase
    end
endmodule