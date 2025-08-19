module signed_divider_8bit (
    input clk,
    input rst_n,
    input signed [7:0] a,
    input signed [7:0] b,
    input valid_in,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder,
    output reg valid_out
);

    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [7:0] q;
    reg [7:0] r;
    reg [3:0] count;
    reg sign_q;
    reg sign_r;
    
    wire is_neg_a = a[7];
    wire is_neg_b = b[7];
    wire [7:0] abs_a = is_neg_a ? -a : a;
    wire [7:0] abs_b = is_neg_b ? -b : b;
    wire r_is_neg = r[7];
    wire count_done = (count == 4'd7);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE: next_state = valid_in ? CALC : IDLE;
            CALC: next_state = count_done ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    wire [7:0] r_shifted = {r[6:0], dividend[7-count]};
    wire [7:0] r_sub = r_shifted - divisor;
    wire [7:0] r_add = r_shifted + divisor;
    wire [7:0] q_shifted = {q[6:0], 1'b1};
    wire [7:0] q_shifted_zero = {q[6:0], 1'b0};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend <= 8'd0;
            divisor <= 8'd0;
            q <= 8'd0;
            r <= 8'd0;
            count <= 4'd0;
            sign_q <= 1'b0;
            sign_r <= 1'b0;
            quotient <= 8'd0;
            remainder <= 8'd0;
            valid_out <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        dividend <= abs_a;
                        divisor <= abs_b;
                        sign_q <= is_neg_a ^ is_neg_b;
                        sign_r <= is_neg_a;
                        q <= 8'd0;
                        r <= 8'd0;
                        count <= 4'd0;
                        valid_out <= 1'b0;
                    end
                end
                
                CALC: begin
                    r <= r_is_neg ? r_add : r_sub;
                    q <= r_is_neg ? q_shifted_zero : q_shifted;
                    count <= count + 4'd1;
                end
                
                DONE: begin
                    if (r_is_neg) begin
                        r <= r + divisor;
                        q <= q - 8'd1;
                    end
                    quotient <= sign_q ? -q : q;
                    remainder <= sign_r ? -r : r;
                    valid_out <= 1'b1;
                end
                
                default: valid_out <= 1'b0;
            endcase
        end
    end

endmodule