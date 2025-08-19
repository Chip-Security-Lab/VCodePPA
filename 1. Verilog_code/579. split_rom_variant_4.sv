//SystemVerilog
// ROM storage module for the lower 8 bits
module rom_lower (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    wire [7:0] rom_data;
    
    initial begin
        rom[0] = 8'h12; 
        rom[1] = 8'h34;
        // Initialize other values as needed
    end
    
    // Combinational logic for ROM read
    assign rom_data = rom[addr];
    
    // Sequential logic for output register
    always @(posedge clk) begin
        data <= rom_data;
    end
endmodule

// ROM storage module for the upper 8 bits
module rom_upper (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    wire [7:0] rom_data;
    
    initial begin
        rom[0] = 8'hAB; 
        rom[1] = 8'hCD;
        // Initialize other values as needed
    end
    
    // Combinational logic for ROM read
    assign rom_data = rom[addr];
    
    // Sequential logic for output register
    always @(posedge clk) begin
        data <= rom_data;
    end
endmodule

// Data concatenation module
module data_concat (
    input [7:0] upper_data,
    input [7:0] lower_data,
    output [15:0] concat_data
);
    assign concat_data = {upper_data, lower_data};
endmodule

// Top-level module
module split_rom (
    input clk,
    input [3:0] addr,
    output [15:0] data
);
    wire [7:0] upper_data;
    wire [7:0] lower_data;
    
    rom_upper upper_rom (
        .clk(clk),
        .addr(addr),
        .data(upper_data)
    );
    
    rom_lower lower_rom (
        .clk(clk),
        .addr(addr),
        .data(lower_data)
    );
    
    data_concat concat (
        .upper_data(upper_data),
        .lower_data(lower_data),
        .concat_data(data)
    );
endmodule