//SystemVerilog
module dynamic_reset_path(
    input wire clk,
    input wire [1:0] path_select,
    input wire [3:0] reset_sources,
    output reg reset_out
);
    // Register the input signals first
    reg [1:0] path_select_reg;
    reg [3:0] reset_sources_reg;
    
    // First stage: register inputs
    always @(posedge clk) begin
        path_select_reg <= path_select;
        reset_sources_reg <= reset_sources;
    end
    
    // Second stage: perform selection with registered inputs
    always @(posedge clk) begin
        case (path_select_reg)
            2'b00: reset_out <= reset_sources_reg[0];
            2'b01: reset_out <= reset_sources_reg[1];
            2'b10: reset_out <= reset_sources_reg[2];
            2'b11: reset_out <= reset_sources_reg[3];
        endcase
    end
endmodule