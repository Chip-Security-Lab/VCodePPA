//SystemVerilog
module sram_dynamic #(
    parameter MAX_DEPTH = 1024,
    parameter DW = 32
)(
    input clk,
    input [31:0] config_word,
    input we,
    input [31:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// Register stage for configuration signals
reg [15:0] configured_width_reg;
reg [15:0] configured_depth_reg;
reg [31:0] config_word_reg;

// Register stage for memory control signals
reg [DW-1:0] mem [0:MAX_DEPTH-1];
reg [DW-1:0] read_data;
reg [DW-1:0] width_mask_reg;
reg [15:0] actual_width_reg;
reg [15:0] actual_depth_reg;
reg [31:0] addr_reg;
reg we_reg;
reg [DW-1:0] din_reg;

// First pipeline stage - register configuration inputs
always @(posedge clk) begin
    config_word_reg <= config_word;
    configured_width_reg <= config_word[15:0];
    configured_depth_reg <= config_word[31:16];
    addr_reg <= addr;
    we_reg <= we;
    din_reg <= din;
end

// Second pipeline stage - compute actual dimensions
always @(posedge clk) begin
    if (configured_width_reg == 0) begin
        actual_width_reg <= DW;
    end else if (configured_width_reg > DW) begin
        actual_width_reg <= DW;
    end else begin
        actual_width_reg <= configured_width_reg;
    end

    if (configured_depth_reg == 0) begin
        actual_depth_reg <= MAX_DEPTH;
    end else if (configured_depth_reg > MAX_DEPTH) begin
        actual_depth_reg <= MAX_DEPTH;
    end else begin
        actual_depth_reg <= configured_depth_reg;
    end

    width_mask_reg <= (1 << actual_width_reg) - 1;
end

// Write operation with registered inputs
always @(posedge clk) begin
    if (we_reg && (addr_reg < actual_depth_reg)) begin
        if (actual_width_reg == DW) begin
            mem[addr_reg] <= din_reg;
        end else begin
            mem[addr_reg] <= (mem[addr_reg] & ~width_mask_reg) | (din_reg & width_mask_reg);
        end
    end
end

// Read operation with registered inputs
always @(posedge clk) begin
    if (addr_reg < actual_depth_reg) begin
        if (actual_width_reg == DW) begin
            read_data <= mem[addr_reg];
        end else begin
            read_data <= mem[addr_reg] & width_mask_reg;
        end
    end else begin
        read_data <= 0;
    end
end

assign dout = read_data;

endmodule