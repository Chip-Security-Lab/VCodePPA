//SystemVerilog
// Top-level module
module Demux_RingBuffer #(
    parameter DW = 8,   // Data width
    parameter N = 8     // Buffer depth
) (
    input wire clk,
    input wire wr_en,
    input wire [$clog2(N)-1:0] ptr,
    input wire [DW-1:0] data_in,
    output wire [N-1:0][DW-1:0] buffer
);

    // Local signals
    wire [$clog2(N)-1:0] next_ptr;
    wire [N-1:0] write_select;
    wire [N-1:0] clear_select;

    // Address generation submodule
    Address_Generator #(
        .N(N)
    ) addr_gen_inst (
        .ptr(ptr),
        .next_ptr(next_ptr)
    );

    // Decoder submodule
    Write_Decoder #(
        .N(N)
    ) decoder_inst (
        .ptr(ptr),
        .next_ptr(next_ptr),
        .write_select(write_select),
        .clear_select(clear_select)
    );

    // Buffer storage submodule
    Buffer_Storage #(
        .DW(DW),
        .N(N)
    ) buffer_storage_inst (
        .clk(clk),
        .wr_en(wr_en),
        .write_select(write_select),
        .clear_select(clear_select),
        .data_in(data_in),
        .buffer(buffer)
    );

endmodule

// Submodule for address generation
module Address_Generator #(
    parameter N = 8
) (
    input wire [$clog2(N)-1:0] ptr,
    output wire [$clog2(N)-1:0] next_ptr
);

    assign next_ptr = (ptr + 1) % N;

endmodule

// Submodule for decoding write and clear signals
module Write_Decoder #(
    parameter N = 8
) (
    input wire [$clog2(N)-1:0] ptr,
    input wire [$clog2(N)-1:0] next_ptr,
    output wire [N-1:0] write_select,
    output wire [N-1:0] clear_select
);

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : decoder_loop
            assign write_select[i] = (ptr == i[$clog2(N)-1:0]);
            assign clear_select[i] = (next_ptr == i[$clog2(N)-1:0]);
        end
    endgenerate

endmodule

// Submodule for buffer storage
module Buffer_Storage #(
    parameter DW = 8,
    parameter N = 8
) (
    input wire clk,
    input wire wr_en,
    input wire [N-1:0] write_select,
    input wire [N-1:0] clear_select,
    input wire [DW-1:0] data_in,
    output reg [N-1:0][DW-1:0] buffer
);

    integer j;
    
    always @(posedge clk) begin
        if (wr_en) begin
            for (j = 0; j < N; j = j + 1) begin
                if (write_select[j]) begin
                    buffer[j] <= data_in;
                end
                else if (clear_select[j]) begin
                    buffer[j] <= {DW{1'b0}};
                end
            end
        end
    end

endmodule