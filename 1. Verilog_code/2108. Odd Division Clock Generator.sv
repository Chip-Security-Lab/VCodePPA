module odd_div_clk_gen #(
    parameter DIV = 3  // Must be odd number
)(
    input clk_in,
    input rst,
    output reg clk_out
);
    localparam HALF = (DIV-1)/2;
    reg [$clog2(DIV)-1:0] count;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count <= 0;
            clk_out <= 0;
        end else begin
            if (count == DIV-1) begin
                count <= 0;
            end else begin
                count <= count + 1;
            end
            
            if (count == 0 || count == HALF+1)
                clk_out <= ~clk_out;
        end
    end
endmodule