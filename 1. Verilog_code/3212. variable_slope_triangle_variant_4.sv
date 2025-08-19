//SystemVerilog
module variable_slope_triangle(
    input clk_in,
    input reset,
    input [7:0] up_slope_rate,
    input [7:0] down_slope_rate,
    output reg [7:0] triangle_out
);
    reg direction;  // 0 = up, 1 = down
    reg [7:0] counter;
    reg [1:0] state;
    
    // State encoding
    localparam IDLE = 2'b00;
    localparam COUNT_UP = 2'b01;
    localparam COUNT_DOWN = 2'b10;
    
    always @(posedge clk_in) begin
        if (reset) begin
            triangle_out <= 8'b0;
            direction <= 1'b0;
            counter <= 8'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    counter <= counter + 8'b1;
                    if (!direction && (counter >= up_slope_rate)) begin
                        state <= COUNT_UP;
                        counter <= 8'b0;
                    end else if (direction && (counter >= down_slope_rate)) begin
                        state <= COUNT_DOWN;
                        counter <= 8'b0;
                    end
                end
                
                COUNT_UP: begin
                    if (triangle_out == 8'hff) begin
                        direction <= 1'b1;
                        state <= IDLE;
                    end else begin
                        triangle_out <= triangle_out + 8'b1;
                        state <= IDLE;
                    end
                end
                
                COUNT_DOWN: begin
                    if (triangle_out == 8'h00) begin
                        direction <= 1'b0;
                        state <= IDLE;
                    end else begin
                        triangle_out <= triangle_out - 8'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule