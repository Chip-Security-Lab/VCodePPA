module binary_weight_divider(
    input clock,
    input reset,
    output [4:0] clk_div_powers
);
    reg [4:0] counter;
    
    always @(posedge clock or posedge reset) begin
        if (reset)
            counter <= 5'b00000;
        else
            counter <= counter + 5'b00001;
    end
    
    assign clk_div_powers = {counter[4], counter[3], counter[2], counter[1], counter[0]};
endmodule