//SystemVerilog
module TriStateNOT(
    input wire clk,         // Clock input
    input wire rst_n,       // Active-low reset
    input wire oe,          // Output enable
    input wire [3:0] in,    // Input data bus
    output reg [3:0] out    // Output data bus
);
    // Internal signals
    reg oe_reg;             // Register for output enable
    reg [3:0] not_in;       // Combinational inversion result
    reg [3:0] in_reg;       // Register for input data
    
    // Combinational inversion logic - moved before register
    always @(*) begin
        not_in = ~in;
    end
    
    // First pipeline stage: Register inputs and inverted data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg <= 4'b0000;
            oe_reg <= 1'b0;
        end else begin
            in_reg <= not_in;  // Store inverted data directly
            oe_reg <= oe;
        end
    end
    
    // Output stage: Apply output enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 4'bzzzz;
        end else begin
            out <= oe_reg ? in_reg : 4'bzzzz;
        end
    end
endmodule