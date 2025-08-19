module signed_divider_8bit (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient,
    output signed [7:0] remainder
);

    reg signed [7:0] a_reg, b_reg, quotient_reg, remainder_reg;
    reg signed [15:0] x, d, f;
    reg [2:0] iter;
    reg [1:0] state;
    
    localparam IDLE = 2'b00, INIT = 2'b01, ITER = 2'b10, DONE = 2'b11;
    
    // Optimized state machine
    always @(*) begin
        case(state)
            IDLE: state = (b != 0) ? INIT : IDLE;
            INIT: state = ITER;
            ITER: state = (iter == 3'd4) ? DONE : ITER;
            DONE: state = IDLE;
        endcase
    end
    
    // Optimized Goldschmidt division
    always @(*) begin
        case(state)
            INIT: begin
                a_reg = a;
                b_reg = b;
                x = {a_reg, 8'b0};
                d = {b_reg, 8'b0};
                f = 16'h0100 - d[15:8];
                iter = 3'd0;
            end
            ITER: begin
                x = x * f;
                d = d * f;
                f = 16'h0200 - d[15:8];
                iter = iter + 1;
            end
            DONE: begin
                quotient_reg = x[15:8];
                remainder_reg = sub_result;
            end
        endcase
    end
    
    // Optimized carry-lookahead subtractor
    wire [7:0] b_inv = ~b_reg;
    wire [7:0] p = a_reg ^ b_inv;
    wire [7:0] g = a_reg & b_inv;
    
    // Optimized carry generation using parallel prefix
    wire [7:0] carry;
    assign carry[0] = 1'b1;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1:0] == 2'b11);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2:1] == 2'b11 & g[0]) | (p[2:0] == 3'b111);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3:2] == 2'b11 & g[1]) | (p[3:1] == 3'b111 & g[0]) | (p[3:0] == 4'b1111);
    assign carry[5] = g[4] | (p[4] & g[3]) | (p[4:3] == 2'b11 & g[2]) | (p[4:2] == 3'b111 & g[1]) | (p[4:1] == 4'b1111 & g[0]) | (p[4:0] == 5'b11111);
    assign carry[6] = g[5] | (p[5] & g[4]) | (p[5:4] == 2'b11 & g[3]) | (p[5:3] == 3'b111 & g[2]) | (p[5:2] == 4'b1111 & g[1]) | (p[5:1] == 5'b11111 & g[0]) | (p[5:0] == 6'b111111);
    assign carry[7] = g[6] | (p[6] & g[5]) | (p[6:5] == 2'b11 & g[4]) | (p[6:4] == 3'b111 & g[3]) | (p[6:3] == 4'b1111 & g[2]) | (p[6:2] == 5'b11111 & g[1]) | (p[6:1] == 6'b111111 & g[0]) | (p[6:0] == 7'b1111111);
    
    wire [7:0] sub_result = p ^ carry;
    wire carry_out = carry[7];
    wire borrow_out = ~carry[7];
    
    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    
endmodule