//SystemVerilog
module loadable_div #(parameter W=4) (
    input clk, load, 
    input [W-1:0] div_val,
    output reg clk_out
);
    // Registered values
    reg [W-1:0] cnt;
    reg is_zero;
    
    // Optimized next counter logic
    wire [W-1:0] decremented_cnt = cnt - 1'b1;
    wire counter_at_zero = (cnt == {W{1'b0}});
    
    // Clock and counter update logic
    always @(posedge clk) begin
        // Counter update logic
        if (load)
            cnt <= div_val;
        else if (counter_at_zero)
            cnt <= div_val;
        else
            cnt <= decremented_cnt;
        
        // Clock output logic - optimized to avoid glitches
        if (load)
            clk_out <= 1'b1;
        else
            clk_out <= !counter_at_zero;
    end
endmodule