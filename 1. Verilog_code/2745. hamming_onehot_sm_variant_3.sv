//SystemVerilog
module hamming_onehot_sm(
    input clk, rst, start,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg done
);
    // State definitions
    reg [3:0] state, next_state;
    parameter S_IDLE = 4'b0001, S_CALC = 4'b0010, S_WRITE = 4'b0100, S_DONE = 4'b1000;
    
    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state; // Default: stay in current state
        
        case (state)
            S_IDLE: if (start) next_state = S_CALC;
            S_CALC: next_state = S_WRITE;
            S_WRITE: next_state = S_DONE;
            S_DONE: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end
    
    // Data path logic (Hamming encoding)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
        end else if (state == S_CALC) begin
            encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
            encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
            encoded[2] <= data_in[0];
            encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
            encoded[4] <= data_in[1];
            encoded[5] <= data_in[2];
            encoded[6] <= data_in[3];
        end
    end
    
    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
        end else if (state == S_DONE) begin
            done <= 1'b1;
        end else if (state == S_IDLE) begin
            done <= 1'b0;
        end
    end
endmodule