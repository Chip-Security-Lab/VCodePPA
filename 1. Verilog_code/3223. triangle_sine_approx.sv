module triangle_sine_approx(
    input clk,
    input reset,
    output reg [7:0] sine_out
);
    reg [7:0] triangle;
    reg up_down;
    
    // Generate triangle wave
    always @(posedge clk) begin
        if (reset) begin
            triangle <= 8'd0;
            up_down <= 1'b1;
        end else begin
            if (up_down) begin
                if (triangle == 8'd255)
                    up_down <= 1'b0;
                else
                    triangle <= triangle + 8'd1;
            end else begin
                if (triangle == 8'd0)
                    up_down <= 1'b1;
                else
                    triangle <= triangle - 8'd1;
            end
        end
    end
    
    // Apply a simple cubic-like transformation to triangle to approximate sine
    always @(posedge clk) begin
        if (triangle < 8'd64)
            sine_out <= 8'd64 + (triangle >> 1);
        else if (triangle < 8'd192)
            sine_out <= 8'd96 + (triangle >> 1);
        else
            sine_out <= 8'd192 + (triangle >> 2);
    end
endmodule