module selective_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] bit_mask,
    input wire update,
    output reg [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // Update main register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 0;
        else
            data_reg <= data_in;
    end
    
    // Selective update of shadow register based on bit mask
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out <= 0;
        end else if (update) begin
            shadow_out <= (data_reg & bit_mask) | (shadow_out & ~bit_mask);
        end
    end
endmodule