module duty_cycle_clk #(
    parameter HIGH_CYCLE = 2,
    parameter TOTAL_CYCLE = 4
)(
    input clk,
    input rstb,
    output clk_out
);
    reg [7:0] cycle_counter;
    
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            cycle_counter <= 8'd0;
        end else begin
            if (cycle_counter >= TOTAL_CYCLE - 1)
                cycle_counter <= 8'd0;
            else
                cycle_counter <= cycle_counter + 1'b1;
        end
    end
    
    assign clk_out = (cycle_counter < HIGH_CYCLE) ? 1'b1 : 1'b0;
endmodule