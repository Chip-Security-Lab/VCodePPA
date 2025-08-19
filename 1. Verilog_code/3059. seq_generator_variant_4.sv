//SystemVerilog
module seq_generator(
    input wire clk, rst, enable,
    input wire [3:0] pattern,
    input wire load_pattern,
    output reg seq_out,
    output reg valid,
    input wire ready
);
    reg [3:0] state, next_state;
    reg [3:0] seq_pattern;
    reg valid_next;
    
    // Manchester carry chain adder signals
    wire [3:0] carry;
    wire [3:0] sum;
    
    // Generate carry chain
    assign carry[0] = 1'b0;
    assign carry[1] = (state[0] & 1'b1) | (state[0] & carry[0]) | (1'b1 & carry[0]);
    assign carry[2] = (state[1] & 1'b1) | (state[1] & carry[1]) | (1'b1 & carry[1]);
    assign carry[3] = (state[2] & 1'b1) | (state[2] & carry[2]) | (1'b1 & carry[2]);
    
    // Generate sum
    assign sum[0] = state[0] ^ 1'b1 ^ carry[0];
    assign sum[1] = state[1] ^ 1'b1 ^ carry[1];
    assign sum[2] = state[2] ^ 1'b1 ^ carry[2];
    assign sum[3] = state[3] ^ 1'b1 ^ carry[3];
    
    always @(posedge clk)
        if (rst) begin
            state <= 4'd0;
            seq_pattern <= 4'b0101;
            valid <= 1'b0;
        end else begin
            state <= next_state;
            valid <= valid_next;
            if (load_pattern) seq_pattern <= pattern;
        end
    
    always @(*) begin
        next_state = state;
        valid_next = valid;
        
        if (enable) begin
            if (state == 4'd3) begin
                next_state = 4'd0;
                valid_next = 1'b1;
            end else begin
                next_state = sum;
                valid_next = 1'b0;
            end
        end
        
        if (ready && valid) begin
            valid_next = 1'b0;
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