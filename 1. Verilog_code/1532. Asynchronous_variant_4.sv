//SystemVerilog
module async_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shadow_en,
    output reg [WIDTH-1:0] shadow_out
);
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] shadow_reg;
    reg shadow_en_reg;
    
    // Combined always block with the same trigger condition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            data_in_reg <= 0;
            shadow_en_reg <= 0;
            shadow_reg <= 0;
            shadow_out <= 0;
        end else begin
            // Register input signals
            data_in_reg <= data_in;
            shadow_en_reg <= shadow_en;
            
            // Shadow register logic
            if (shadow_en_reg)
                shadow_reg <= data_in_reg;
                
            // Output logic
            shadow_out <= shadow_en_reg ? data_in_reg : shadow_reg;
        end
    end
endmodule