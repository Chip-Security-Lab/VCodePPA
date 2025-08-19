module quad_encoder_timer (
    input wire clk, rst, quad_a, quad_b, timer_en,
    output reg [15:0] position,
    output reg [31:0] timer
);
    reg a_prev, b_prev;
    wire count_up, count_down;
    always @(posedge clk) begin
        if (rst) begin a_prev <= 1'b0; b_prev <= 1'b0; end
        else begin a_prev <= quad_a; b_prev <= quad_b; end
    end
    assign count_up = quad_a ^ b_prev;
    assign count_down = quad_b ^ a_prev;
    always @(posedge clk) begin
        if (rst) position <= 16'h0000;
        else if (quad_a != a_prev || quad_b != b_prev)
            position <= (count_up) ? position + 1'b1 : 
                       (count_down) ? position - 1'b1 : position;
    end
    always @(posedge clk) begin
        if (rst) timer <= 32'h0;
        else if (timer_en) timer <= timer + 32'h1;
    end
endmodule