//SystemVerilog
module binary_weight_divider(
    input clock,
    input reset,
    output [4:0] clk_div_powers
);
    reg [4:0] counter;
    
    always @(posedge clock or posedge reset)
        counter <= reset ? 5'b00000 : counter + 5'b00001;
    
    assign clk_div_powers = counter;
endmodule