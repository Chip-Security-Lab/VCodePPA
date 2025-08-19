//SystemVerilog
// ROM initialization module with improved structure
module rom_init (
    output reg [7:0] rom [0:255]
);
    // Split initialization into multiple smaller always blocks for better modularity
    always @(*) begin
        // Initialize first quarter of ROM
        for (int i = 0; i < 64; i++) begin
            rom[i] = i;
        end
    end
    
    always @(*) begin
        // Initialize second quarter of ROM
        for (int i = 64; i < 128; i++) begin
            rom[i] = i;
        end
    end
    
    always @(*) begin
        // Initialize third quarter of ROM
        for (int i = 128; i < 192; i++) begin
            rom[i] = i;
        end
    end
    
    always @(*) begin
        // Initialize fourth quarter of ROM
        for (int i = 192; i < 256; i++) begin
            rom[i] = i;
        end
    end
endmodule

// ROM read module with optimized structure
module rom_read (
    input [3:0] addr_a,
    input [3:0] addr_b,
    input [7:0] rom [0:255],
    output reg [7:0] product
);
    // Split address calculation and ROM access for better timing
    reg [7:0] addr_combined;
    
    always @(*) begin
        addr_combined = {addr_a, addr_b};
    end
    
    always @(*) begin
        product = rom[addr_combined];
    end
endmodule

// Top level module with improved structure
module rom_based_mult (
    input [3:0] addr_a,
    input [3:0] addr_b,
    output [7:0] product
);
    // Use localparam for better readability and maintainability
    localparam ROM_SIZE = 256;
    
    // Declare ROM as a wire array
    wire [7:0] rom [0:ROM_SIZE-1];
    
    // Instantiate ROM initialization module
    rom_init rom_init_inst (
        .rom(rom)
    );
    
    // Instantiate ROM read module
    rom_read rom_read_inst (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .rom(rom),
        .product(product)
    );
    
endmodule