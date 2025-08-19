//SystemVerilog
module pwm_timer #(
    parameter COUNTER_WIDTH = 12
)(
    input clk_i,
    input rst_n_i,
    input [COUNTER_WIDTH-1:0] period_i,
    input [COUNTER_WIDTH-1:0] duty_i,
    output reg pwm_o
);
    reg [COUNTER_WIDTH-1:0] counter;
    
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            pwm_o <= 1'b0;
        end else if (counter >= period_i - 1'b1) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            if (duty_i > 0) begin
                pwm_o <= 1'b1;
            end else begin
                pwm_o <= 1'b0;
            end
        end else begin
            counter <= counter + 1'b1;
            if ((counter + 1'b1) < duty_i) begin
                pwm_o <= 1'b1;
            end else begin
                pwm_o <= 1'b0;
            end
        end
    end
endmodule