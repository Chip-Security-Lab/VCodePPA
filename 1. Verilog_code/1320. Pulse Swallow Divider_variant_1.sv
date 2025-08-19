//SystemVerilog
module pulse_swallow_div (
    input clk_in, reset, swallow_en,
    input [3:0] swallow_val,
    output reg clk_out
);
    reg [3:0] counter;
    reg swallow;
    
    // Buffer registers for high fan-out counter signal
    reg [3:0] counter_buf1; // Buffer for comparison with swallow_val
    reg [3:0] counter_buf2; // Buffer for comparison with 4'd7
    
    always @(posedge clk_in) begin
        if (reset) begin
            counter <= 4'd0;
            counter_buf1 <= 4'd0;
            counter_buf2 <= 4'd0;
            clk_out <= 1'b0;
            swallow <= 1'b0;
        end else begin
            // Update buffer registers for counter
            counter_buf1 <= counter;
            counter_buf2 <= counter;
            
            if (swallow_en && counter_buf1 == swallow_val) begin
                swallow <= 1'b1;
            end else if (counter_buf2 == 4'd7) begin
                counter <= 4'd0;
                clk_out <= ~clk_out;
                swallow <= 1'b0;
            end else if (!swallow)
                counter <= counter + 1'b1;
        end
    end
endmodule