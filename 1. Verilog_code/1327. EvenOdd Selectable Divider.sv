module even_odd_divider (
    input CLK, RESET, ODD_DIV,
    output reg DIV_CLK
);
    reg [2:0] counter;
    reg half_cycle;
    wire terminal_count;
    
    assign terminal_count = ODD_DIV ? 
                    (counter == 3'b100 && half_cycle) || (counter == 3'b100 && !half_cycle) :
                    (counter == 3'b100);
    
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter <= 3'b000;
            half_cycle <= 1'b0;
            DIV_CLK <= 1'b0;
        end else if (terminal_count) begin
            counter <= 3'b000;
            half_cycle <= ODD_DIV ? ~half_cycle : half_cycle;
            DIV_CLK <= ~DIV_CLK;
        end else
            counter <= counter + 1'b1;
    end
endmodule