//SystemVerilog
module mem_mapped_reset_ctrl(
    input wire clk,
    input wire [3:0] addr,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] reset_outputs
);
    // Register input signals to improve timing at inputs
    reg [3:0] addr_reg;
    reg [7:0] data_in_reg;
    reg write_en_reg;
    
    // First stage: register inputs
    always @(posedge clk) begin
        addr_reg <= addr;
        data_in_reg <= data_in;
        write_en_reg <= write_en;
    end
    
    // Decoded control signals using registered inputs
    wire addr_match_0 = (addr_reg == 4'h0);
    wire addr_match_1 = (addr_reg == 4'h1);
    wire addr_match_2 = (addr_reg == 4'h2);
    
    // Combined enable signals
    wire load_new = write_en_reg && addr_match_0;
    wire set_bits = write_en_reg && addr_match_1;
    wire clear_bits = write_en_reg && addr_match_2;
    
    // Second stage: update output registers
    always @(posedge clk) begin
        if (load_new)
            reset_outputs <= data_in_reg;
        else if (set_bits)
            reset_outputs <= reset_outputs | data_in_reg;
        else if (clear_bits)
            reset_outputs <= reset_outputs & ~data_in_reg;
    end
endmodule