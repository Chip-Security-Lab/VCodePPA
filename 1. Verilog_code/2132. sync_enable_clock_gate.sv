module sync_enable_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire enable,
    output wire clk_out
);
    reg enable_reg;
    
    always @(negedge clk_in or negedge rst_n) begin
        if (!rst_n)
            enable_reg <= 1'b0;
        else
            enable_reg <= enable;
    end
    
    assign clk_out = clk_in & enable_reg;
endmodule