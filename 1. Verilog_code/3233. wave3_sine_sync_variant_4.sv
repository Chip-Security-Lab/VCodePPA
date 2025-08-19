//SystemVerilog
module wave3_sine_sync #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // Initialize ROM using $readmemh
    // Assuming a file named "rom_init.mem" exists in the simulation/synthesis directory
    // The file should contain (1<<ADDR_WIDTH) lines, each with a hex value
    // representing i % (1<<DATA_WIDTH) for i from 0 to (1<<ADDR_WIDTH)-1
    // Example content for rom_init.mem (ADDR_WIDTH=6, DATA_WIDTH=8):
    // 00
    // 01
    // ...
    // 3F
    initial begin
        $readmemh("rom_init.mem", rom);
    end

    always @(posedge clk) begin
        addr <= rst ? {ADDR_WIDTH{1'b0}} : addr + 1; // Use conditional operator for reset logic
        wave_out <= rom[addr];
    end
endmodule