//SystemVerilog
// Top-level module: onehot2bin
// Function: Converts one-hot input to binary output using pipelined hierarchical submodules

module onehot2bin #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3 // Explicit output width, to avoid $clog2
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [OH_WIDTH-1:0]   onehot_in,
    output wire [OUT_WIDTH-1:0]  bin_out
);

    // Stage 1: Register input for pipelined dataflow
    reg [OH_WIDTH-1:0] onehot_in_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_in_stage1 <= {OH_WIDTH{1'b0}};
        else
            onehot_in_stage1 <= onehot_in;
    end

    // Stage 2: Pipeline register for encoder output
    wire [OUT_WIDTH-1:0] encoded_index_stage2;

    onehot_encoder_pipeline #(
        .OH_WIDTH(OH_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_onehot_encoder_pipeline (
        .clk         (clk),
        .rst_n       (rst_n),
        .onehot_in   (onehot_in_stage1),
        .index_out   (encoded_index_stage2)
    );

    // Stage 3: Output register for clear dataflow and improved timing closure
    reg [OUT_WIDTH-1:0] bin_out_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_out_stage3 <= {OUT_WIDTH{1'b0}};
        else
            bin_out_stage3 <= encoded_index_stage2;
    end

    assign bin_out = bin_out_stage3;

endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot_encoder_pipeline
// Function: Encodes a one-hot input vector to its binary index with pipelining
// -----------------------------------------------------------------------------
module onehot_encoder_pipeline #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [OH_WIDTH-1:0]   onehot_in,
    output wire [OUT_WIDTH-1:0]  index_out
);

    // Stage 1: Combinational priority encoder (flattened, shallow logic)
    reg [OUT_WIDTH-1:0] encoder_comb_stage1;
    integer idx;

    always @(*) begin : encoder_comb_block
        encoder_comb_stage1 = {OUT_WIDTH{1'b0}};
        for (idx = OH_WIDTH-1; idx >= 0; idx = idx - 1) begin
            if (onehot_in[idx])
                encoder_comb_stage1 = idx[OUT_WIDTH-1:0];
        end
    end

    // Stage 2: Register encoder output to break long logic chain
    reg [OUT_WIDTH-1:0] encoder_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encoder_stage2 <= {OUT_WIDTH{1'b0}};
        else
            encoder_stage2 <= encoder_comb_stage1;
    end

    assign index_out = encoder_stage2;

endmodule