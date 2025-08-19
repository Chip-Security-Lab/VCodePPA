//SystemVerilog
// Gray to Binary conversion module
module gray2bin_unit #(parameter DATA_WIDTH = 8) (
    input  [DATA_WIDTH-1:0] gray_data,
    output [DATA_WIDTH-1:0] binary_data
);

    // Internal signals for intermediate XOR results
    wire [DATA_WIDTH-1:0] xor_results;

    // Generate XOR tree for each bit position
    genvar gv;
    generate
        for (gv = 0; gv < DATA_WIDTH; gv = gv + 1) begin : g2b_conv
            assign xor_results[gv] = ^(gray_data >> gv);
        end
    endgenerate

    // Output assignment
    assign binary_data = xor_results;

endmodule

// Gray to Binary conversion with pipelining
module gray2bin_pipelined #(
    parameter DATA_WIDTH = 8,
    parameter PIPELINE_STAGES = 2
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [DATA_WIDTH-1:0]    gray_data,
    output reg  [DATA_WIDTH-1:0]    binary_data
);

    // Pipeline registers
    reg [DATA_WIDTH-1:0] pipeline_regs [PIPELINE_STAGES-1:0];
    wire [DATA_WIDTH-1:0] comb_output;

    // Instantiate combinational Gray to Binary converter
    gray2bin_unit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) g2b_inst (
        .gray_data(gray_data),
        .binary_data(comb_output)
    );

    // Pipeline stages
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                pipeline_regs[i] <= {DATA_WIDTH{1'b0}};
            end
            binary_data <= {DATA_WIDTH{1'b0}};
        end else begin
            pipeline_regs[0] <= comb_output;
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                pipeline_regs[i] <= pipeline_regs[i-1];
            end
            binary_data <= pipeline_regs[PIPELINE_STAGES-1];
        end
    end

endmodule

// Top-level module with configurable parameters
module gray2bin_top #(
    parameter DATA_WIDTH = 8,
    parameter PIPELINE_STAGES = 2,
    parameter USE_PIPELINE = 1
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [DATA_WIDTH-1:0]    gray_data,
    output wire [DATA_WIDTH-1:0]    binary_data
);

    generate
        if (USE_PIPELINE) begin : gen_pipeline
            gray2bin_pipelined #(
                .DATA_WIDTH(DATA_WIDTH),
                .PIPELINE_STAGES(PIPELINE_STAGES)
            ) g2b_pipe_inst (
                .clk(clk),
                .rst_n(rst_n),
                .gray_data(gray_data),
                .binary_data(binary_data)
            );
        end else begin : gen_comb
            gray2bin_unit #(
                .DATA_WIDTH(DATA_WIDTH)
            ) g2b_comb_inst (
                .gray_data(gray_data),
                .binary_data(binary_data)
            );
        end
    endgenerate

endmodule