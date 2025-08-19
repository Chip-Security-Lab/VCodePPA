module start_delay_clk(
    input clk_i,
    input rst_i,
    input [7:0] delay,
    output reg clk_o
);
    reg [7:0] delay_counter;
    reg [3:0] div_counter;
    reg started;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            delay_counter <= 8'd0;
            div_counter <= 4'd0;
            clk_o <= 1'b0;
            started <= 1'b0;
        end else if (!started) begin
            if (delay_counter >= delay) begin
                started <= 1'b1;
                delay_counter <= 8'd0;
            end else
                delay_counter <= delay_counter + 8'd1;
        end else begin
            if (div_counter == 4'd9) begin
                div_counter <= 4'd0;
                clk_o <= ~clk_o;
            end else
                div_counter <= div_counter + 4'd1;
        end
    end
endmodule