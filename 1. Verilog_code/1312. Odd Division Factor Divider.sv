module odd_div #(parameter DIV = 3) (
    input clk_i, reset_i,
    output reg clk_o
);
    reg [$clog2(DIV)-1:0] counter;
    
    always @(posedge clk_i) begin
        if (reset_i) begin
            counter <= 0;
            clk_o <= 0;
        end else if (counter == DIV - 1) begin
            counter <= 0;
            clk_o <= ~clk_o;
        end else
            counter <= counter + 1;
    end
endmodule