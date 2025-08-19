//SystemVerilog
//IEEE 1364-2005 Verilog

// Top-level module - Pipelined Tristate Decoder
module tristate_decoder #(
    parameter ADDR_WIDTH = 2,
    parameter OUT_WIDTH = 4
)(
    input wire clk,                      // Added clock for pipelining
    input wire rst_n,                    // Added reset signal
    input wire [ADDR_WIDTH-1:0] addr,
    input wire enable,
    output wire [OUT_WIDTH-1:0] select
);
    // Internal pipeline registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg enable_stage1, enable_stage2;
    wire [OUT_WIDTH-1:0] decoded_bus;
    reg [OUT_WIDTH-1:0] decoded_stage2;
    
    // Stage 1: Input Capture and Address Processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            enable_stage1 <= enable;
        end
    end
    
    // Address Decoding - Instantiate optimized decoder module
    decoder_datapath #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) decoder_inst (
        .addr(addr_stage1),
        .decoded(decoded_bus)
    );
    
    // Stage 2: Decoded Data Capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_stage2 <= {OUT_WIDTH{1'b0}};
            enable_stage2 <= 1'b0;
        end else begin
            decoded_stage2 <= decoded_bus;
            enable_stage2 <= enable_stage1;
        end
    end
    
    // Output Stage: Tristate Control
    tristate_output_stage #(
        .WIDTH(OUT_WIDTH)
    ) output_stage (
        .enable(enable_stage2),
        .data_in(decoded_stage2),
        .data_out(select)
    );
endmodule

// Optimized decoder datapath module
module decoder_datapath #(
    parameter ADDR_WIDTH = 2,
    parameter OUT_WIDTH = 4
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [OUT_WIDTH-1:0] decoded
);
    // Address validation
    wire valid_addr = (addr < OUT_WIDTH);
    
    // Optimized one-hot decoding with pre-validation
    always @(*) begin
        decoded = {OUT_WIDTH{1'b0}}; // Default all outputs to 0
        if (valid_addr) begin
            decoded[addr] = 1'b1;    // Set only the addressed bit
        end
    end
endmodule

// Enhanced tristate output stage module
module tristate_output_stage #(
    parameter WIDTH = 4
)(
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // Efficient tristate buffer implementation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : tristate_buffer
            assign data_out[i] = enable ? data_in[i] : 1'bz;
        end
    endgenerate
endmodule