module clock_derived_square(
    input main_clk,
    input reset,
    output reg [3:0] clk_div_out
);
    reg [7:0] div_counter;
    
    always @(posedge main_clk) begin
        if (reset) begin
            div_counter <= 8'd0;
            clk_div_out <= 4'b0000;
        end else begin
            div_counter <= div_counter + 8'd1;
            
            // Generate different frequency outputs
            clk_div_out[0] <= div_counter[0];  // Divide by 2
            clk_div_out[1] <= div_counter[1];  // Divide by 4
            clk_div_out[2] <= div_counter[3];  // Divide by 16
            clk_div_out[3] <= div_counter[5];  // Divide by 64
        end
    end
endmodule
