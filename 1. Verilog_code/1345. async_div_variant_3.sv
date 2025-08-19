//SystemVerilog
module async_div #(parameter DIV=4) (
    input wire clk_in,
    output wire clk_out
);
    reg [3:0] counter;
    reg clk_div;
    
    // Counter logic
    always @(posedge clk_in) begin
        if (counter >= DIV-1)
            counter <= 4'b0000;
        else
            counter <= counter + 1'b1;
    end
    
    // Clock output generation
    always @(posedge clk_in) begin
        if (counter == 4'b0000)
            clk_div <= 1'b0;
        else if (counter == (DIV >> 1))
            clk_div <= 1'b1;
    end
    
    // Output assignment with parameter bounds check
    assign clk_out = (DIV <= 4) ? clk_div : (counter < (DIV >> 1));
    
endmodule