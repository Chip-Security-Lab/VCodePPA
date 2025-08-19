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

    wire [15:0] configured_width;
    wire [15:0] configured_depth;
    wire [15:0] actual_width;
    wire [15:0] actual_depth;
    wire [DW-1:0] width_mask;
    wire [DW-1:0] read_data;

    config_decoder #(
        .DW(DW),
        .MAX_DEPTH(MAX_DEPTH)
    ) u_config_decoder (
        .config_word(config_word),
        .configured_width(configured_width),
        .configured_depth(configured_depth),
        .actual_width(actual_width),
        .actual_depth(actual_depth)
    );

    mask_generator #(
        .DW(DW)
    ) u_mask_generator (
        .actual_width(actual_width),
        .width_mask(width_mask)
    );

    memory_core #(
        .MAX_DEPTH(MAX_DEPTH),
        .DW(DW)
    ) u_memory_core (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .width_mask(width_mask),
        .actual_depth(actual_depth),
        .actual_width(actual_width),
        .dout(read_data)
    );

    assign dout = read_data;

endmodule

module config_decoder #(
    parameter DW = 32,
    parameter MAX_DEPTH = 1024
)(
    input [31:0] config_word,
    output [15:0] configured_width,
    output [15:0] configured_depth,
    output [15:0] actual_width,
    output [15:0] actual_depth
);

    assign configured_width = config_word[15:0];
    assign configured_depth = config_word[31:16];
    
    assign actual_width = (configured_width == 0) ? DW : 
                         (configured_width > DW) ? DW : configured_width;
                          
    assign actual_depth = (configured_depth == 0) ? MAX_DEPTH : 
                         (configured_depth > MAX_DEPTH) ? MAX_DEPTH : configured_depth;

endmodule

module mask_generator #(
    parameter DW = 32
)(
    input [15:0] actual_width,
    output [DW-1:0] width_mask
);

    generate
        genvar i;
        for (i = 0; i < DW; i = i + 1) begin : mask_gen
            assign width_mask[i] = (i < actual_width) ? 1'b1 : 1'b0;
        end
    endgenerate

endmodule

module memory_core #(
    parameter MAX_DEPTH = 1024,
    parameter DW = 32
)(
    input clk,
    input we,
    input [31:0] addr,
    input [DW-1:0] din,
    input [DW-1:0] width_mask,
    input [15:0] actual_depth,
    input [15:0] actual_width,
    output [DW-1:0] dout
);

    reg [DW-1:0] mem [0:MAX_DEPTH-1];
    reg [DW-1:0] read_data;

    always @(posedge clk) begin
        if (we && (addr < actual_depth)) begin
            if (actual_width == DW) begin
                mem[addr] <= din;
            end else begin
                mem[addr] <= (mem[addr] & ~width_mask) | (din & width_mask);
            end
        end
    end

    always @(posedge clk) begin
        if (addr < actual_depth) begin
            if (actual_width == DW) begin
                read_data <= mem[addr];
            end else begin
                read_data <= mem[addr] & width_mask;
            end
        end else begin
            read_data <= 0;
        end
    end

    assign dout = read_data;

endmodule