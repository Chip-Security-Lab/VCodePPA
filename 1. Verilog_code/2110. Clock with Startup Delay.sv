module clk_with_delay(
    input clk_in,
    input rst_n,
    input [3:0] delay_cycles,
    output reg clk_out
);
    reg [3:0] counter;
    reg running;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            running <= 1'b0;
            clk_out <= 1'b0;
        end else if (!running) begin
            if (counter >= delay_cycles) begin
                running <= 1'b1;
                counter <= 4'd0;
            end else
                counter <= counter + 1'b1;
        end else
            clk_out <= ~clk_out;
    end
endmodule