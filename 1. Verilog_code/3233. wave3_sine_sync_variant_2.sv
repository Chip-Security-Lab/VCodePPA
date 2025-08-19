//SystemVerilog
// SystemVerilog
// Top-level module: wave3_sine_sync
// Generates a synchronous sine wave output by using an address generator and a waveform ROM.
// This module orchestrates the data flow between the address generation and the ROM lookup.
module wave3_sine_sync #(
    parameter ADDR_WIDTH = 6, // Width of the ROM address bus
    parameter DATA_WIDTH = 8  // Width of the output data bus
)(
    input  wire                  clk,      // Clock signal
    input  wire                  rst,      // Reset signal (active high)
    output wire  [DATA_WIDTH-1:0] wave_out  // Synchronous output from the waveform ROM
);

    // Internal wire to connect the output of the address generator to the input of the ROM
    wire [ADDR_WIDTH-1:0] rom_addr;

    // Instantiate the address generator sub-module
    // This module is responsible for generating sequential addresses for the ROM.
    address_generator #(
        .ADDR_WIDTH(ADDR_WIDTH) // Pass the address width parameter
    ) u_addr_gen (
        .clk(clk),        // Connect clock
        .rst(rst),        // Connect reset
        .addr(rom_addr)   // Connect output address to the ROM address wire
    );

    // Instantiate the waveform ROM sub-module
    // This module stores the pre-calculated sine wave data and outputs the value
    // corresponding to the input address. The output is registered.
    waveform_rom #(
        .ADDR_WIDTH(ADDR_WIDTH), // Pass the address width parameter
        .DATA_WIDTH(DATA_WIDTH)  // Pass the data width parameter
    ) u_rom (
        .clk(clk),          // Connect clock
        .addr(rom_addr),    // Connect input address from the generator
        .data_out(wave_out) // Connect output waveform data to the module output
    );

endmodule

// Sub-module: address_generator
// This module generates a simple incrementing address sequence.
// It is a synchronous counter that resets to zero.
module address_generator #(
    parameter ADDR_WIDTH = 6 // Width of the output address
)(
    input  wire                 clk,  // Clock signal
    input  wire                 rst,  // Reset signal (active high)
    output reg [ADDR_WIDTH-1:0] addr  // Output address register
);

    // Address counter logic
    always @(posedge clk) begin
        if(rst) begin
            // Reset address to zero
            addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            // Increment address on each clock edge
            addr <= addr + 1;
        end
    end

endmodule

// Sub-module: waveform_rom
// This module acts as a look-up table (ROM) storing waveform data.
// It reads data based on the input address and provides a registered output.
// It is typically inferred as a block RAM in FPGAs for better performance and resource usage.
module waveform_rom #(
    parameter ADDR_WIDTH = 6, // Width of the address input
    parameter DATA_WIDTH = 8  // Width of the data output
)(
    input  wire                  clk,      // Clock signal for registered output
    input  wire  [ADDR_WIDTH-1:0] addr,     // Input address to look up data
    output reg  [DATA_WIDTH-1:0] data_out  // Registered output data from the ROM
);

    // Declare the ROM memory array
    // Size is 2^ADDR_WIDTH locations, each DATA_WIDTH bits wide.
    // Attribute to guide synthesis tool to use block RAM if available for better PPA.
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // Initialize the ROM with waveform data (e.g., sine wave values)
    // This initial block is typically used for synthesizing ROM contents.
    initial begin
        integer i;
        // Example initialization: Simple linear ramp for simulation/basic test
        // Replace with actual sine wave generation logic for a real sine ROM.
        // For a sine wave: rom[i] = calculate_sine_value(i, ADDR_WIDTH, DATA_WIDTH);
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
            // Simple pattern: value wraps around DATA_WIDTH
            rom[i] = i % (1<<DATA_WIDTH);
            // For actual sine wave values, more complex calculation or loading from a file is needed.
            // Example placeholder (requires fixed-point math):
            // rom[i] = $rtoi($sin(i * 2.0 * $pi / (1<<ADDR_WIDTH)) * (1.0 * (1<<(DATA_WIDTH-1)) - 1) + (1<<(DATA_WIDTH-1)));
        end
    end

    // Read from ROM based on the input address and register the output
    // This infers a synchronous read with registered output, suitable for block RAMs.
    always @(posedge clk) begin
        data_out <= rom[addr];
    end

endmodule