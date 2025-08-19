//SystemVerilog
module async_divider (
    input  wire master_clk,
    input  wire reset_n,
    input  wire enable,
    output wire div2_clk,
    output wire div4_clk,
    output wire div8_clk,
    output wire valid_out
);
    // Clock divider counters
    reg [2:0] div_counter;
    reg valid_out_reg;
    
    // Optimized clock division logic with single counter
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_counter <= 3'b000;
            valid_out_reg <= 1'b0;
        end else if (enable) begin
            // Toggle bit 0 on every enabled clock cycle
            div_counter[0] <= ~div_counter[0];
            
            // Toggle bit 1 when bit 0 transitions from 1 to 0
            if (div_counter[0] == 1'b1)
                div_counter[1] <= ~div_counter[1];
                
            // Toggle bit 2 when bit 1 transitions from 1 to 0
            if (div_counter[1:0] == 2'b10)
                div_counter[2] <= ~div_counter[2];
                
            valid_out_reg <= 1'b1;
        end
    end
    
    // Output assignments
    assign div2_clk = div_counter[0];
    assign div4_clk = div_counter[1];
    assign div8_clk = div_counter[2];
    assign valid_out = valid_out_reg;
    
endmodule