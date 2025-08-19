module sram_dynamic #(
    parameter MAX_DEPTH = 1024,
    parameter DW = 32
)(
    input clk,
    input [31:0] config_word, // [31:16] depth, [15:0] data width
    input we,
    input [31:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
// Fixed implementation that's synthesizable
wire [15:0] configured_width = config_word[15:0];
wire [15:0] configured_depth = config_word[31:16];

// Use fixed-size memory with dynamic access control
reg [DW-1:0] mem [0:MAX_DEPTH-1];
reg [DW-1:0] read_data;

wire [15:0] actual_width = (configured_width == 0) ? DW : 
                           (configured_width > DW) ? DW : configured_width;
                           
wire [15:0] actual_depth = (configured_depth == 0) ? MAX_DEPTH : 
                          (configured_depth > MAX_DEPTH) ? MAX_DEPTH : configured_depth;

// Write operation
always @(posedge clk) begin
    if (we && (addr < actual_depth)) begin
        // Only write the active bits based on configured width
        if (actual_width == DW) begin
            mem[addr] <= din;
        end else begin
            // Create a mask for the lower bits based on actual width
            mem[addr] <= (mem[addr] & ~((1 << actual_width) - 1)) | (din & ((1 << actual_width) - 1));
        end
    end
end

// Read operation
always @(posedge clk) begin
    if (addr < actual_depth) begin
        if (actual_width == DW) begin
            read_data <= mem[addr];
        end else begin
            // Zero-extend to full width
            read_data <= mem[addr] & ((1 << actual_width) - 1);
        end
    end else begin
        read_data <= 0;
    end
end

assign dout = read_data;

endmodule