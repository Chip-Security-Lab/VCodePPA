//SystemVerilog
// Top-level module: polarity_conv
// Structured pipelined dataflow with clear data path stages

module polarity_conv #(
    parameter MODE = 0
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [15:0]  in,
    output wire [15:0]  out
);

    // Stage 1: Input register
    reg [15:0] data_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_stage1 <= 16'd0;
        else
            data_stage1 <= in;
    end

    // Stage 2: Polarity inversion and offset addition operations in parallel
    wire [15:0] polarity_stage2;
    wire [15:0] offset_stage2;

    polarity_inverter_pipe u_polarity_inverter_pipe (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_stage1),
        .data_out (polarity_stage2)
    );

    offset_adder_pipe u_offset_adder_pipe (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_stage1),
        .data_out (offset_stage2)
    );

    // Stage 3: Output selection register
    reg [15:0] out_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_stage3 <= 16'd0;
        else
            out_stage3 <= MODE ? polarity_stage2 : offset_stage2;
    end

    assign out = out_stage3;

endmodule

// -----------------------------------------------------------------------------
// Submodule: polarity_inverter_pipe
// Function: Pipeline stage for polarity inversion
// -----------------------------------------------------------------------------
module polarity_inverter_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    output reg  [15:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 16'd0;
        else
            data_out <= {~data_in[15], data_in[14:0]};
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: offset_adder_pipe
// Function: Pipeline stage for offset addition
// -----------------------------------------------------------------------------
module offset_adder_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    output reg  [15:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 16'd0;
        else
            data_out <= data_in + 16'd32768;
    end
endmodule