module dynamic_divider (
    input clock, reset_b, load,
    input [7:0] divide_value,
    output reg divided_clock
);
    reg [7:0] divider_reg;
    reg [7:0] counter;
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter <= 8'h0;
            divider_reg <= 8'h1;
            divided_clock <= 1'b0;
        end else begin
            if (load)
                divider_reg <= divide_value;
                
            if (counter >= divider_reg - 1) begin
                counter <= 8'h0;
                divided_clock <= ~divided_clock;
            end else
                counter <= counter + 1'b1;
        end
    end
endmodule