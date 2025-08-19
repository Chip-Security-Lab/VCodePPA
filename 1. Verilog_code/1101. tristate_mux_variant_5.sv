//SystemVerilog
// Top-level module: Structured Pipelined Tristate Multiplexer
module tristate_mux (
    input  wire        clk,                // System clock for pipelining
    input  wire        rst_n,              // Asynchronous active-low reset
    input  wire [7:0]  source_a,           // Data source A
    input  wire [7:0]  source_b,           // Data source B
    input  wire        select,             // Selection control
    input  wire        output_enable,      // Output enable
    output wire [7:0]  data_bus            // Tristate output bus
);

    // Stage 1: Input Registration
    wire [7:0] source_a_stage1;
    wire [7:0] source_b_stage1;
    wire       select_stage1;
    wire       output_enable_stage1;

    pipeline_reg_input u_pipeline_reg_input (
        .clk                (clk),
        .rst_n              (rst_n),
        .source_a_in        (source_a),
        .source_b_in        (source_b),
        .select_in          (select),
        .output_enable_in   (output_enable),
        .source_a_out       (source_a_stage1),
        .source_b_out       (source_b_stage1),
        .select_out         (select_stage1),
        .output_enable_out  (output_enable_stage1)
    );

    // Stage 2: Multiplexing
    wire [7:0] mux_data_stage2;

    mux2to1_8bit_pipeline u_mux2to1_8bit_pipeline (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_a       (source_a_stage1),
        .in_b       (source_b_stage1),
        .sel        (select_stage1),
        .mux_out    (mux_data_stage2)
    );

    // Stage 3: Output Enable Registration
    wire output_enable_stage2;

    pipeline_reg_output_enable u_pipeline_reg_output_enable (
        .clk                (clk),
        .rst_n              (rst_n),
        .output_enable_in   (output_enable_stage1),
        .output_enable_out  (output_enable_stage2)
    );

    // Stage 4: Tristate Buffer
    tristate_buffer_8bit_structured u_tristate_buffer_8bit_structured (
        .data_in    (mux_data_stage2),
        .en         (output_enable_stage2),
        .data_out   (data_bus)
    );

endmodule

// Stage 1: Pipeline Register for Inputs
module pipeline_reg_input (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  source_a_in,
    input  wire [7:0]  source_b_in,
    input  wire        select_in,
    input  wire        output_enable_in,
    output reg  [7:0]  source_a_out,
    output reg  [7:0]  source_b_out,
    output reg         select_out,
    output reg         output_enable_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            source_a_out      <= 8'b0;
            source_b_out      <= 8'b0;
            select_out        <= 1'b0;
            output_enable_out <= 1'b0;
        end else begin
            source_a_out      <= source_a_in;
            source_b_out      <= source_b_in;
            select_out        <= select_in;
            output_enable_out <= output_enable_in;
        end
    end
endmodule

// Stage 2: Pipelined 8-bit 2-to-1 Multiplexer
module mux2to1_8bit_pipeline (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  in_a,
    input  wire [7:0]  in_b,
    input  wire        sel,
    output reg  [7:0]  mux_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out <= 8'b0;
        end else begin
            mux_out <= sel ? in_b : in_a;
        end
    end
endmodule

// Stage 3: Pipeline Register for Output Enable
module pipeline_reg_output_enable (
    input  wire clk,
    input  wire rst_n,
    input  wire output_enable_in,
    output reg  output_enable_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_enable_out <= 1'b0;
        end else begin
            output_enable_out <= output_enable_in;
        end
    end
endmodule

// Stage 4: Structured 8-bit Tristate Buffer
module tristate_buffer_8bit_structured (
    input  wire [7:0] data_in,
    input  wire       en,
    output wire [7:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_tristate_buffer
            assign data_out[i] = en ? data_in[i] : 1'bz;
        end
    endgenerate
endmodule