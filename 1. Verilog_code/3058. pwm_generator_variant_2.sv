//SystemVerilog
module pwm_generator(
    input wire clk, reset,
    input wire [7:0] duty_cycle,
    input wire update,
    output reg pwm_out
);
    reg [7:0] counter;
    reg [7:0] counter_buf;
    reg [7:0] duty_reg;
    reg loading, next_loading;
    
    always @(posedge clk or posedge reset)
        if (reset) begin
            counter <= 8'd0;
            counter_buf <= 8'd0;
            duty_reg <= 8'd0;
            loading <= 1'b0;
        end else begin
            counter <= counter + 8'd1;
            counter_buf <= counter;
            loading <= next_loading;
            if (loading) duty_reg <= duty_cycle;
        end
    
    always @(*) begin
        pwm_out = (counter_buf < duty_reg);
        next_loading = (counter == 8'd255) & update;
    end
endmodule