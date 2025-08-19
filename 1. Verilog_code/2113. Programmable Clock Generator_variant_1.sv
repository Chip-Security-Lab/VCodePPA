//SystemVerilog
module programmable_clk_gen(
    input sys_clk,        // System clock
    input sys_rst_n,      // System reset (active low)
    input [15:0] divisor, // Clock divisor value
    input update,         // Update divisor value
    output reg clk_out    // Output clock
);
    reg [15:0] div_counter;
    reg [15:0] div_value;
    
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_counter <= 16'd0;
            div_value <= 16'd1;
            clk_out <= 1'b0;
        end else if (update) begin
            div_value <= divisor;
            if (div_counter >= div_value - 1) begin
                div_counter <= 16'd0;
                clk_out <= ~clk_out;
            end else begin
                div_counter <= div_counter + 16'd1;
            end
        end else if (div_counter >= div_value - 1) begin
            div_counter <= 16'd0;
            clk_out <= ~clk_out;
        end else begin
            div_counter <= div_counter + 16'd1;
        end
    end
endmodule