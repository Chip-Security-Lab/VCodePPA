//SystemVerilog
module binary_weight_divider(
    input clock,
    input reset,
    output [4:0] clk_div_powers
);
    reg [4:0] counter;
    reg [4:0] counter_buf1;
    reg [4:0] counter_buf2;
    
    always @(posedge clock or posedge reset) begin
        if (reset)
            counter <= 5'b00000;
        else
            counter <= counter + 5'b00001;
    end
    
    // First level buffer for high fanout counter signal
    always @(posedge clock or posedge reset) begin
        if (reset)
            counter_buf1 <= 5'b00000;
        else
            counter_buf1 <= counter;
    end
    
    // Second level buffer to further distribute fanout load
    always @(posedge clock or posedge reset) begin
        if (reset)
            counter_buf2 <= 5'b00000;
        else
            counter_buf2 <= counter_buf1;
    end
    
    // Use buffered signals to drive output
    assign clk_div_powers = {counter_buf2[4], counter_buf2[3], counter_buf1[2], counter_buf1[1], counter[0]};
endmodule