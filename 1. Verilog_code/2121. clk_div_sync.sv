module clk_div_sync #(
    parameter DIV = 4
)(
    input clk_in,
    input rst_n,
    input en,
    output reg clk_out
);
    reg [31:0] counter;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
            clk_out <= 1'b0;
        end else if (en) begin
            if (counter >= (DIV/2) - 1) begin
                counter <= 32'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule