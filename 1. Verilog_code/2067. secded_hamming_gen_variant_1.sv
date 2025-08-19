//SystemVerilog
// Top-level SECDED Hamming generator module with pipelined, structured data path

module secded_hamming_gen #(
    parameter DATA_WIDTH = 64
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [DATA_WIDTH-1:0]     data_in,
    output wire [DATA_WIDTH+7:0]     hamming_out  // 64 data + 8 ECC
);

    // Stage 1: Register input data
    wire [DATA_WIDTH-1:0]            data_stage1;
    pipeline_reg #(
        .WIDTH(DATA_WIDTH)
    ) u_data_stage1_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (data_in),
        .dout       (data_stage1)
    );

    // Stage 2: Generate 7 Hamming parity bits
    wire [6:0]                       parity_stage2;
    secded_parity_gen #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_parity_gen (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_stage1),
        .parity_out (parity_stage2)
    );

    // Stage 2.5: Register parity and data for alignment
    wire [6:0]                       parity_stage2p5;
    wire [DATA_WIDTH-1:0]            data_stage2p5;
    pipeline_reg #(
        .WIDTH(6+1)
    ) u_parity_stage2p5_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (parity_stage2),
        .dout       (parity_stage2p5)
    );
    pipeline_reg #(
        .WIDTH(DATA_WIDTH)
    ) u_data_stage2p5_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (data_stage1),
        .dout       (data_stage2p5)
    );

    // Stage 3: Generate overall parity
    wire                             overall_parity_stage3;
    secded_overall_parity #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_overall_parity (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_stage2p5),
        .parity_in      (parity_stage2p5),
        .overall_parity (overall_parity_stage3)
    );

    // Stage 3.5: Register overall parity, data, and parity for alignment
    wire                             overall_parity_stage3p5;
    wire [6:0]                       parity_stage3p5;
    wire [DATA_WIDTH-1:0]            data_stage3p5;
    pipeline_reg #(
        .WIDTH(1)
    ) u_overall_parity_stage3p5_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (overall_parity_stage3),
        .dout       (overall_parity_stage3p5)
    );
    pipeline_reg #(
        .WIDTH(6+1)
    ) u_parity_stage3p5_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (parity_stage2p5),
        .dout       (parity_stage3p5)
    );
    pipeline_reg #(
        .WIDTH(DATA_WIDTH)
    ) u_data_stage3p5_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (data_stage2p5),
        .dout       (data_stage3p5)
    );

    // Stage 4: Output combiner
    secded_output_combiner #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_output_combiner (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_stage3p5),
        .parity_in      (parity_stage3p5),
        .overall_parity (overall_parity_stage3p5),
        .hamming_out    (hamming_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Pipeline Register Module
// Generic register for pipelining
// -----------------------------------------------------------------------------
module pipeline_reg #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {WIDTH{1'b0}};
        else
            dout <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// submodule: secded_parity_gen
// Function: Generates the 7 Hamming parity bits for the input data vector
// -----------------------------------------------------------------------------
module secded_parity_gen #(
    parameter DATA_WIDTH = 64
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output reg  [6:0]             parity_out
);
    reg [6:0] parity_comb;
    always @(*) begin
        parity_comb[0] = ^(data_in & 64'hAAAAAAAAAAAAAAAA); // Even bits
        parity_comb[1] = ^(data_in & 64'hCCCCCCCCCCCCCCCC); // 2-bit groups
        parity_comb[2] = ^(data_in & 64'hF0F0F0F0F0F0F0F0); // 4-bit groups
        parity_comb[3] = ^(data_in & 64'hFF00FF00FF00FF00); // 8-bit groups
        parity_comb[4] = ^(data_in & 64'hFFFF0000FFFF0000); // 16-bit groups
        parity_comb[5] = ^(data_in & 64'hFFFFFFFF00000000); // 32-bit groups
        parity_comb[6] = ^(data_in & 64'hFFFFFFFFFFFFFFFE); // All except bit 0
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity_out <= 7'b0;
        else
            parity_out <= parity_comb;
    end
endmodule

// -----------------------------------------------------------------------------
// submodule: secded_overall_parity
// Function: Generates the overall parity bit for SECDED (Single Error Correction, Double Error Detection)
// -----------------------------------------------------------------------------
module secded_overall_parity #(
    parameter DATA_WIDTH = 64
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire [6:0]             parity_in,
    output reg                    overall_parity
);
    reg overall_parity_comb;
    always @(*) begin
        overall_parity_comb = ^{data_in, parity_in};
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            overall_parity <= 1'b0;
        else
            overall_parity <= overall_parity_comb;
    end
endmodule

// -----------------------------------------------------------------------------
// submodule: secded_output_combiner
// Function: Concatenates parity bits and data into the SECDED output vector
// -----------------------------------------------------------------------------
module secded_output_combiner #(
    parameter DATA_WIDTH = 64
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [DATA_WIDTH-1:0]    data_in,
    input  wire [6:0]               parity_in,
    input  wire                     overall_parity,
    output reg  [DATA_WIDTH+7:0]    hamming_out
);
    reg [DATA_WIDTH+7:0] hamming_comb;
    always @(*) begin
        hamming_comb = {parity_in, overall_parity, data_in};
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hamming_out <= {DATA_WIDTH+8{1'b0}};
        else
            hamming_out <= hamming_comb;
    end
endmodule