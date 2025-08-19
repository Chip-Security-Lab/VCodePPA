//SystemVerilog
module power_on_reset_delay #(parameter DELAY_COUNT = 16'd1000)(
    input  wire clk,
    input  wire external_reset_n,
    output reg  reset_n
);
    reg [15:0] delay_counter = 16'd0;
    reg        power_stable = 1'b0;

    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            delay_counter  <= 16'd0;
            power_stable   <= 1'b0;
            reset_n        <= 1'b0;
        end else begin
            if (!power_stable) begin
                if (delay_counter < (DELAY_COUNT - 1)) begin
                    delay_counter <= delay_counter + 16'd1;
                end else begin
                    delay_counter <= delay_counter;
                    power_stable  <= 1'b1;
                end
            end
            reset_n <= power_stable;
        end
    end
endmodule