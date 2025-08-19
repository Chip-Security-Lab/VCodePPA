//SystemVerilog
module odd_div #(parameter DIV = 3) (
    input clk_i, reset_i,
    output reg clk_o
);
    reg [$clog2(DIV)-1:0] counter;
    reg next_clk_o;
    
    // Next state logic - moved before the register
    always @(*) begin
        next_clk_o = clk_o;
        if (reset_i)
            next_clk_o = 1'b0;
        else if (counter == DIV - 1)
            next_clk_o = ~clk_o;
    end
    
    // Register update
    always @(posedge clk_i) begin
        if (reset_i) begin
            counter <= 0;
        end 
        else if (counter == DIV - 1) begin
            counter <= 0;
        end 
        else begin
            counter <= counter + 1;
        end
        
        clk_o <= next_clk_o;
    end
endmodule