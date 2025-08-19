module seq_generator(
    input wire clk, rst, enable,
    input wire [3:0] pattern,
    input wire load_pattern,
    output reg seq_out
);
    reg [3:0] state, next_state;
    reg [3:0] seq_pattern;
    
    always @(posedge clk)
        if (rst) begin
            state <= 4'd0;
            seq_pattern <= 4'b0101;
        end else begin
            state <= next_state;
            if (load_pattern) seq_pattern <= pattern;
        end
    
    always @(*) begin
        next_state = state;
        if (enable) begin
            if (state == 4'd3)
                next_state = 4'd0;
            else
                next_state = state + 4'd1;
        end
        
        case (state)
            4'd0: seq_out = seq_pattern[0];
            4'd1: seq_out = seq_pattern[1];
            4'd2: seq_out = seq_pattern[2];
            4'd3: seq_out = seq_pattern[3];
            default: seq_out = 1'b0;
        endcase
    end
endmodule