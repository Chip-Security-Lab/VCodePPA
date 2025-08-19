module variable_slope_triangle(
    input clk_in,
    input reset,
    input [7:0] up_slope_rate,
    input [7:0] down_slope_rate,
    output reg [7:0] triangle_out
);
    reg direction;  // 0 = up, 1 = down
    reg [7:0] counter;
    
    always @(posedge clk_in) begin
        if (reset) begin
            triangle_out <= 8'b0;
            direction <= 1'b0;
            counter <= 8'b0;
        end else begin
            counter <= counter + 8'b1;
            
            if (!direction && (counter >= up_slope_rate)) begin
                counter <= 8'b0;
                if (triangle_out == 8'hff)
                    direction <= 1'b1;
                else
                    triangle_out <= triangle_out + 8'b1;
            end else if (direction && (counter >= down_slope_rate)) begin
                counter <= 8'b0;
                if (triangle_out == 8'h00)
                    direction <= 1'b0;
                else
                    triangle_out <= triangle_out - 8'b1;
            end
        end
    end
endmodule