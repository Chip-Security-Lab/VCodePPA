//SystemVerilog
module freq_divider(
    input wire clk_in, rst_n,
    input wire [15:0] div_ratio,
    input wire update_ratio,
    output reg clk_out
);
    localparam IDLE=1'b0, DIVIDE=1'b1;
    reg state, next;
    reg [15:0] counter;
    reg [15:0] div_value;
    reg [15:0] half_div_reg;
    reg counter_match_reg;
    reg clk_out_next;
    
    wire [15:0] half_div;
    wire counter_match;
    
    assign half_div = {1'b0, div_value[15:1]};
    assign counter_match = (counter >= (half_div - 1));
    
    always @(posedge clk_in or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            div_value <= 16'd2;
            half_div_reg <= 16'd1;
            counter_match_reg <= 1'b0;
            clk_out <= 1'b0;
            clk_out_next <= 1'b0;
        end else begin
            state <= next;
            half_div_reg <= half_div;
            counter_match_reg <= counter_match;
            clk_out <= clk_out_next;
            
            if (update_ratio)
                div_value <= (|div_ratio[15:1]) ? div_ratio : 16'd2;
                
            if (state == IDLE)
                counter <= 16'd0;
            else if (state == DIVIDE) begin
                counter <= counter + 16'd1;
                if (counter_match_reg) begin
                    counter <= 16'd0;
                    clk_out_next <= ~clk_out;
                end
            end
        end
    
    always @(*)
        if (state == IDLE)
            next = DIVIDE;
        else if (state == DIVIDE)
            next = DIVIDE;
        else
            next = IDLE;
endmodule