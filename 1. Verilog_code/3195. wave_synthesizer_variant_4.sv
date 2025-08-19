//SystemVerilog
module wave_synthesizer #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,  // Active-low reset for better timing
    output reg  [DATA_WIDTH-1:0]    wave_out,
    output reg                      valid_out
);

// Pipeline stage registers with clear naming convention
reg [ADDR_WIDTH-1:0] addr_counter;
reg [ADDR_WIDTH-1:0] addr_stage1;
reg [DATA_WIDTH-1:0] data_stage1;
reg                  valid_stage1;

// Predefined sine wave lookup table
reg [DATA_WIDTH-1:0] sine_rom [0:2**ADDR_WIDTH-1];
initial $readmemh("sine_table.hex", sine_rom);

// Stage 1: Address generation with improved timing
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_counter <= '0;
        valid_stage1 <= 1'b0;
    end else begin
        addr_counter <= addr_counter + 1'b1;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Memory lookup with intermediate register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= '0;
        data_stage1 <= '0;
    end else begin
        addr_stage1 <= addr_counter;
        data_stage1 <= sine_rom[addr_counter];
    end
end

// Stage 3: Output stage with clear data path
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wave_out <= '0;
        valid_out <= 1'b0;
    end else begin
        wave_out <= data_stage1;
        valid_out <= valid_stage1;
    end
end

endmodule