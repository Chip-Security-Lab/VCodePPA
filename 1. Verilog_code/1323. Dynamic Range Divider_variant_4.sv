//SystemVerilog
module dynamic_divider (
    input clock, reset_b, load,
    input [7:0] divide_value,
    output reg divided_clock
);
    reg [7:0] divider_reg;
    reg [7:0] counter;
    reg counter_max_reg;
    reg [7:0] counter_plus_one;
    reg [7:0] divider_minus_one;
    
    // Stage 1: Pre-compute values to reduce combinational logic depth
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter_plus_one <= 8'h0;
            divider_minus_one <= 8'h0;
        end else begin
            counter_plus_one <= counter + 8'h1;
            divider_minus_one <= divider_reg - 8'h1;
        end
    end
    
    // Stage 2: Comparison logic pipeline stage
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter_max_reg <= 1'b0;
        end else begin
            counter_max_reg <= (counter >= divider_minus_one);
        end
    end
    
    // Counter and clock update logic
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter <= 8'h0;
            divider_reg <= 8'h1;
            divided_clock <= 1'b0;
        end else begin
            // Load operation handled separately
            if (load)
                divider_reg <= divide_value;
                
            // Update counter based on pipeline result
            if (counter_max_reg) begin
                counter <= 8'h0;
                divided_clock <= ~divided_clock;
            end else begin
                counter <= counter_plus_one;
            end
        end
    end
endmodule