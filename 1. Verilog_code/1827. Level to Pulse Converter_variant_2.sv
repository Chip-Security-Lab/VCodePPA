//SystemVerilog
module level2pulse_converter (
    input  wire clk_i,
    input  wire rst_i,
    input  wire level_i,
    output wire pulse_o
);
    reg level_delayed;
    reg level_delayed_ff;
    reg pulse_o_reg;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            level_delayed <= 1'b0;
            level_delayed_ff <= 1'b0;
            pulse_o_reg <= 1'b0;
        end else begin
            level_delayed <= level_i;
            level_delayed_ff <= level_delayed;
            pulse_o_reg <= level_delayed & ~level_delayed_ff;
        end
    end
    
    assign pulse_o = pulse_o_reg;
endmodule