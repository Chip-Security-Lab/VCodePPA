module pwm_generator #(
    parameter CNT_WIDTH = 8
) (
    input  wire                 clock,
    input  wire                 reset_n,
    input  wire [CNT_WIDTH-1:0] duty_cycle,
    output reg                  pwm_out
);
    reg [CNT_WIDTH-1:0] counter;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            pwm_out <= (counter < duty_cycle) ? 1'b1 : 1'b0;
        end
    end
endmodule