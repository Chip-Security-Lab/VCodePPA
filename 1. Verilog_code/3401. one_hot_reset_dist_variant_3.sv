//SystemVerilog
module one_hot_reset_dist(
    input wire clk,
    input wire [1:0] reset_select,
    input wire reset_in,
    output reg [3:0] reset_out
);
    // Register the input signals to move registers backward
    reg reset_in_reg;
    reg [1:0] reset_select_reg;
    
    // Register input signals
    always @(posedge clk) begin
        reset_in_reg <= reset_in;
        reset_select_reg <= reset_select;
    end
    
    // Directly compute output from registered inputs
    always @(posedge clk) begin
        // Default output
        reset_out <= 4'b0000;
        
        // Only set output bits when reset is active
        if (reset_in_reg) begin
            if (reset_select_reg == 2'b00) begin
                reset_out <= 4'b0001;
            end else if (reset_select_reg == 2'b01) begin
                reset_out <= 4'b0010;
            end else if (reset_select_reg == 2'b10) begin
                reset_out <= 4'b0100;
            end else if (reset_select_reg == 2'b11) begin
                reset_out <= 4'b1000;
            end
        end
    end
endmodule