//SystemVerilog
module seq_generator(
    input wire clk, rst,
    input wire req,
    output reg ack,
    input wire [3:0] pattern,
    input wire load_pattern,
    output reg seq_out
);
    reg [3:0] state, next_state;
    reg [3:0] seq_pattern;
    reg req_prev;
    reg [3:0] state_pipe;
    reg seq_out_pipe;
    
    always @(posedge clk)
        if (rst) begin
            state <= 4'd0;
            state_pipe <= 4'd0;
            seq_pattern <= 4'b0101;
            req_prev <= 1'b0;
            ack <= 1'b0;
            seq_out_pipe <= 1'b0;
        end else begin
            state <= next_state;
            state_pipe <= state;
            req_prev <= req;
            if (load_pattern) seq_pattern <= pattern;
            
            if (req && !req_prev) begin
                ack <= 1'b1;
            end else if (!req && req_prev) begin
                ack <= 1'b0;
            end
        end
    
    always @(*) begin
        next_state = state;
        if (req && ack) begin
            if (state == 4'd3)
                next_state = 4'd0;
            else
                next_state = state + 4'd1;
        end
    end
    
    always @(*) begin
        case (state_pipe)
            4'd0: seq_out_pipe = seq_pattern[0];
            4'd1: seq_out_pipe = seq_pattern[1];
            4'd2: seq_out_pipe = seq_pattern[2];
            4'd3: seq_out_pipe = seq_pattern[3];
            default: seq_out_pipe = 1'b0;
        endcase
        seq_out = seq_out_pipe;
    end
endmodule