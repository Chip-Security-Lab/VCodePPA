//SystemVerilog
module wave4_sine_pipelined #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire valid_in, // Input valid signal
    output wire [DATA_WIDTH-1:0] wave_out,
    output wire valid_out   // Output valid signal
);
    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // Initialize ROM content
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
            rom[i] = i % (1<<DATA_WIDTH);
        end
    end

    // Stage 1: Register input address and valid signal
    reg [ADDR_WIDTH-1:0] addr_s1;
    reg valid_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_s1 <= {(ADDR_WIDTH){1'b0}};
            valid_s1 <= 1'b0;
        end else begin
            addr_s1 <= addr;
            valid_s1 <= valid_in;
        end
    end

    // Stage 2 (Retimed): Register the inputs to the ROM lookup.
    // This replaces the original Stage 2 registers which were AFTER the ROM lookup.
    // By moving registers BEFORE the ROM lookup, we perform backward retiming.
    reg [ADDR_WIDTH-1:0] addr_s2;
    reg valid_s2; // Valid signal associated with addr_s2

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_s2 <= {(ADDR_WIDTH){1'b0}};
            valid_s2 <= 1'b0;
        end else begin
            // Capture the outputs of Stage 1
            addr_s2 <= addr_s1;
            valid_s2 <= valid_s1;
        end
    end

    // Combinational ROM lookup based on Stage 2 address
    // This combinational logic now follows the retimed registers (addr_s2, valid_s2)
    wire [DATA_WIDTH-1:0] rom_data_comb;
    assign rom_data_comb = rom[addr_s2];

    // Assign combinational ROM output and Stage 2 valid to module outputs
    // The combinational result directly goes to the output after the retimed registers
    assign wave_out = rom_data_comb;
    assign valid_out = valid_s2;

endmodule