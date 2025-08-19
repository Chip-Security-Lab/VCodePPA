module config_timer #(
    parameter DATA_WIDTH = 24,
    parameter PRESCALE_WIDTH = 8
)(
    input clk_i, rst_i, enable_i,
    input [DATA_WIDTH-1:0] period_i,
    input [PRESCALE_WIDTH-1:0] prescaler_i,
    output reg [DATA_WIDTH-1:0] value_o,
    output expired_o
);
    reg [PRESCALE_WIDTH-1:0] prescale_counter;
    wire prescale_tick = (prescale_counter == prescaler_i);
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= 0; prescale_counter <= 0;
        end else if (enable_i) begin
            prescale_counter <= prescale_tick ? 0 : prescale_counter + 1'b1;
            if (prescale_tick) value_o <= (value_o == period_i) ? 0 : value_o + 1'b1;
        end
    end
    assign expired_o = (value_o == period_i) && prescale_tick;
endmodule