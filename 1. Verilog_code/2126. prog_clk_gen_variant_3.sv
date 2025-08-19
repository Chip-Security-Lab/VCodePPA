//SystemVerilog
module prog_clk_gen(
    input pclk,
    input presetn,
    input [7:0] div_ratio,
    output reg clk_out
);
    reg [7:0] counter;
    reg [7:0] half_div;
    
    // Calculate half_div using shift-and-add algorithm
    // This replaces the direct bit manipulation with an equivalent implementation
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            half_div <= 8'd0;
        end else begin
            half_div <= 8'd0;
            for (int i=0; i<7; i=i+1) begin
                if (div_ratio[i+1]) 
                    half_div[i] <= 1'b1;
            end
        end
    end
    
    // Combined counter and clock logic with improved timing
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            counter <= 8'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= half_div) begin
                counter <= 8'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule