module pulse_swallow_div (
    input clk_in, reset, swallow_en,
    input [3:0] swallow_val,
    output reg clk_out
);
    reg [3:0] counter;
    reg swallow;
    
    always @(posedge clk_in) begin
        if (reset) begin
            counter <= 4'd0;
            clk_out <= 1'b0;
            swallow <= 1'b0;
        end else if (swallow_en && counter == swallow_val) begin
            swallow <= 1'b1;
        end else if (counter == 4'd7) begin
            counter <= 4'd0;
            clk_out <= ~clk_out;
            swallow <= 1'b0;
        end else if (!swallow)
            counter <= counter + 1'b1;
    end
endmodule