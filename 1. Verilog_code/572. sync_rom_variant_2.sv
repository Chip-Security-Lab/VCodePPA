//SystemVerilog
module sync_rom (
    input wire clk,
    input wire [3:0] addr,
    output reg [7:0] data_out
);
    // Memory declaration with improved naming
    (* rom_style = "block" *) reg [7:0] rom_memory [0:15];
    
    // Pipeline registers for improved timing
    reg [3:0] addr_reg;
    reg [7:0] data_reg;
    
    // ROM initialization
    initial begin
        // First half of memory
        rom_memory[0] = 8'h12; rom_memory[1] = 8'h34; 
        rom_memory[2] = 8'h56; rom_memory[3] = 8'h78;
        
        // Second half of memory
        rom_memory[4] = 8'h9A; rom_memory[5] = 8'hBC; 
        rom_memory[6] = 8'hDE; rom_memory[7] = 8'hF0;
        
        // Initialize remaining addresses to zero
        rom_memory[8] = 8'h00; rom_memory[9] = 8'h00;
        rom_memory[10] = 8'h00; rom_memory[11] = 8'h00;
        rom_memory[12] = 8'h00; rom_memory[13] = 8'h00;
        rom_memory[14] = 8'h00; rom_memory[15] = 8'h00;
    end
    
    // Combined pipeline stages - all operations triggered by the same clock edge
    always @(posedge clk) begin
        // Stage 1: Register input address
        addr_reg <= addr;
        
        // Stage 2: Memory lookup with registered address
        data_reg <= rom_memory[addr_reg];
        
        // Stage 3: Register output data
        data_out <= data_reg;
    end
endmodule