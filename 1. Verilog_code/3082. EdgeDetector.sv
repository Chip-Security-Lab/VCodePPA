module EdgeDetector #(
    parameter PULSE_WIDTH = 2
)(
    input clk, rst_async,
    input signal_in,
    output reg rising_edge,
    output reg falling_edge
);
    reg [1:0] sync_reg;

    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            sync_reg <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], signal_in};
        end
    end

    always @(*) begin
        rising_edge = (sync_reg == 2'b01);
        falling_edge = (sync_reg == 2'b10);
    end
endmodule
