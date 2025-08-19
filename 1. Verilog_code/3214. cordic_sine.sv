module cordic_sine(
    input clock,
    input resetn,
    input [7:0] angle_step,
    output reg [9:0] sine_output
);
    reg [9:0] x, y;
    reg [7:0] angle;
    reg [2:0] state;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            x <= 10'd307;       // ~0.6*512
            y <= 10'd0;
            angle <= 8'd0;
            state <= 3'd0;
            sine_output <= 10'd0;
        end else begin
            case (state)
                3'd0: begin
                    angle <= angle + angle_step;
                    state <= 3'd1;
                end
                3'd1: begin
                    // Simple CORDIC approximation
                    if (angle < 8'd128)    // 0 to π/2
                        y <= y + (x >> 3);
                    else                   // π/2 to π
                        y <= y - (x >> 3);
                    state <= 3'd2;
                end
                3'd2: begin
                    sine_output <= y;
                    state <= 3'd0;
                end
                default: state <= 3'd0;
            endcase
        end
    end
endmodule