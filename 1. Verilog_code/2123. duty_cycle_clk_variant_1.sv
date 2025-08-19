//SystemVerilog, IEEE 1364-2005
module duty_cycle_clk #(
    parameter HIGH_CYCLE = 2,
    parameter TOTAL_CYCLE = 4
)(
    input clk,
    input rstb,
    output clk_out
);
    // Use minimum required bits for counter based on TOTAL_CYCLE
    localparam COUNTER_WIDTH = $clog2(TOTAL_CYCLE);
    
    reg [COUNTER_WIDTH-1:0] cycle_counter;
    reg clk_out_reg;
    
    // Optimized counter logic with direct comparison
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            cycle_counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            cycle_counter <= (cycle_counter == TOTAL_CYCLE - 1) ? 
                            {COUNTER_WIDTH{1'b0}} : cycle_counter + 1'b1;
        end
    end
    
    // Optimized output logic using efficient comparison
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            clk_out_reg <= 1'b0;
        end else begin
            // Use equality check for common case of 50% duty cycle
            if (TOTAL_CYCLE == 2 * HIGH_CYCLE) begin
                clk_out_reg <= ~clk_out_reg;
            end 
            // Use simple boundary check for all other cases
            else begin
                clk_out_reg <= (cycle_counter < HIGH_CYCLE);
            end
        end
    end
    
    assign clk_out = clk_out_reg;
endmodule