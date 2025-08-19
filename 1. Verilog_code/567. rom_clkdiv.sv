module rom_clkdiv #(parameter MAX=50000000)(
    input clk,
    output reg clk_out
);
    reg [25:0] counter;
    reg [25:0] max_val = MAX;
    
    always @(posedge clk) begin
        if(counter >= max_val) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
