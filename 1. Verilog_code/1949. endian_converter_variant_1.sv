//SystemVerilog
// Top-level module: Endian Converter with Structured Pipelined Data Path

module endian_converter #(
    parameter WIDTH = 32,
    parameter BYTE_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      big_endian_in,
    output wire [WIDTH-1:0]      little_endian_out
);

    // Number of bytes in the word
    localparam integer NUM_BYTES = WIDTH / BYTE_WIDTH;

    // Pipeline stage 1: Register input for timing closure
    reg [WIDTH-1:0] big_endian_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            big_endian_stage1 <= {WIDTH{1'b0}};
        else
            big_endian_stage1 <= big_endian_in;
    end

    // Pipeline stage 2: Extract bytes and register them
    wire [BYTE_WIDTH-1:0] extracted_bytes [0:NUM_BYTES-1];
    genvar i;
    generate
        for (i = 0; i < NUM_BYTES; i = i + 1) begin: byte_extract_stage
            assign extracted_bytes[i] = big_endian_stage1[(NUM_BYTES-1-i)*BYTE_WIDTH +: BYTE_WIDTH];
        end
    endgenerate

    reg [BYTE_WIDTH-1:0] pipeline_bytes [0:NUM_BYTES-1];
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < NUM_BYTES; j = j + 1)
                pipeline_bytes[j] <= {BYTE_WIDTH{1'b0}};
        end else begin
            for (j = 0; j < NUM_BYTES; j = j + 1)
                pipeline_bytes[j] <= extracted_bytes[j];
        end
    end

    // Pipeline stage 3: Combine bytes into little-endian word and register
    reg [WIDTH-1:0] little_endian_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            little_endian_stage3 <= {WIDTH{1'b0}};
        else begin
            little_endian_stage3 = {WIDTH{1'b0}};
            for (j = 0; j < NUM_BYTES; j = j + 1) begin
                little_endian_stage3[j*BYTE_WIDTH +: BYTE_WIDTH] = pipeline_bytes[j];
            end
        end
    end

    // Output assignment from final pipeline stage
    assign little_endian_out = little_endian_stage3;

endmodule