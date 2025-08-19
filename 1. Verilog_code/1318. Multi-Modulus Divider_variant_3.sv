//SystemVerilog
module multimod_divider (
    input CLK_IN, RST, ENABLE,
    input [2:0] DIV_SEL,
    output reg CLK_OUT
);
    reg [3:0] counter;
    reg [3:0] div_value_reg;
    reg [3:0] div_value_stage1;
    reg enable_stage1;
    
    // Pipeline stage 1: First comparison logic
    wire [3:0] div_value_temp;
    assign div_value_temp = (DIV_SEL == 3'd0) ? 4'd1 :
                            (DIV_SEL == 3'd1) ? 4'd2 : 4'd0;
    
    // Pipeline stage 2: Second comparison logic
    wire [3:0] div_value_comb;
    assign div_value_comb = (div_value_temp != 4'd0) ? div_value_temp :
                            (DIV_SEL == 3'd2) ? 4'd4 :
                            (DIV_SEL == 3'd3) ? 4'd8 : 4'd16;
    
    // Register stage 1 results
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            div_value_stage1 <= 4'd0;
            enable_stage1 <= 1'b0;
        end else begin
            div_value_stage1 <= div_value_comb;
            enable_stage1 <= ENABLE;
        end
    end
    
    // Register stage 2 results
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            div_value_reg <= 4'd1;
        end else begin
            div_value_reg <= div_value_stage1;
        end
    end
    
    // Counter logic with pipelined div_value
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            counter <= 4'd0;
            CLK_OUT <= 1'b0;
        end else if (enable_stage1) begin
            if (counter >= div_value_reg-1) begin
                counter <= 4'd0;
                CLK_OUT <= ~CLK_OUT;
            end else
                counter <= counter + 1'b1;
        end
    end
endmodule