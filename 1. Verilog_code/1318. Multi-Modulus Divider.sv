module multimod_divider (
    input CLK_IN, RST, ENABLE,
    input [2:0] DIV_SEL,
    output reg CLK_OUT
);
    reg [3:0] counter;
    wire [3:0] div_value;
    
    assign div_value = (DIV_SEL == 3'd0) ? 4'd1 :
                       (DIV_SEL == 3'd1) ? 4'd2 :
                       (DIV_SEL == 3'd2) ? 4'd4 :
                       (DIV_SEL == 3'd3) ? 4'd8 : 4'd16;
    
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            counter <= 4'd0;
            CLK_OUT <= 1'b0;
        end else if (ENABLE) begin
            if (counter >= div_value-1) begin
                counter <= 4'd0;
                CLK_OUT <= ~CLK_OUT;
            end else
                counter <= counter + 1'b1;
        end
    end
endmodule