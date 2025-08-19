//SystemVerilog
// SystemVerilog
module wave3_sine_sync_pipelined #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output wire  [DATA_WIDTH-1:0] wave_out
);

    // Internal Signals
    reg [ADDR_WIDTH-1:0] addr_reg;        // Registered address for ROM lookup
    wire [DATA_WIDTH-1:0] rom_read_data;  // Combinational output from ROM read
    reg [DATA_WIDTH-1:0] output_reg;     // Registered output data

    // ROM Definition (Combinational Read based on address)
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // Use system task to initialize ROM
    // This initial block is typically used for simulation.
    // For synthesis, tools might interpret this for Block RAM initialization.
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
            // Simple linear increment for demonstration, replace with sine values
            rom[i] = i % (1<<DATA_WIDTH);
        end
    end

    // --- Combinational Logic ---
    // Read data from ROM based on the current registered address
    assign rom_read_data = rom[addr_reg];

    // Assign the final output from the output register
    assign wave_out = output_reg;

    // --- Sequential Logic ---
    // Stage 1: Address Register - Increments on clock edge
    always @(posedge clk) begin
        if (rst) begin
            addr_reg <= 0;
        end else begin
            addr_reg <= addr_reg + 1;
        end
    end

    // Stage 2: Output Register - Latches the ROM read data on clock edge
    always @(posedge clk) begin
        if (rst) begin
            output_reg <= 0; // Default output value on reset
        end else begin
            output_reg <= rom_read_data;
        end
    end

endmodule