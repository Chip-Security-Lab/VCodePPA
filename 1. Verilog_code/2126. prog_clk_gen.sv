module prog_clk_gen(
    input pclk,
    input presetn,
    input [7:0] div_ratio,
    output reg clk_out
);
    reg [7:0] counter;
    wire [7:0] half_div = {1'b0, div_ratio[7:1]}; // 除以2
    
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            counter <= 8'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= half_div - 1) begin
                counter <= 8'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule