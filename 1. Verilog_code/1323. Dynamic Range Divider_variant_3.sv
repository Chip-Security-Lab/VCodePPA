//SystemVerilog
module dynamic_divider (
    input clock, reset_b, load,
    input [7:0] divide_value,
    output reg divided_clock
);
    reg [7:0] divider_reg;
    reg [7:0] counter;
    reg [7:0] next_count;
    reg next_divided_clock;
    wire counter_reset;
    
    // Pre-compute the comparison result
    assign counter_reset = (counter >= (divider_reg - 8'h1));
    
    // Calculate next state logic outside the always block
    always @(*) begin
        next_count = counter_reset ? 8'h0 : (counter + 8'h1);
        next_divided_clock = counter_reset ? ~divided_clock : divided_clock;
    end
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter <= 8'h0;
            divider_reg <= 8'h1;
            divided_clock <= 1'b0;
        end else if (load) begin
            divider_reg <= divide_value;
            counter <= next_count;
            divided_clock <= next_divided_clock;
        end else begin
            counter <= next_count;
            divided_clock <= next_divided_clock;
        end
    end
endmodule