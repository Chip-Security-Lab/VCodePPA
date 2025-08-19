//SystemVerilog
// Top-level parameterizable pipelined multiplexer module
module param_mux #(
    parameter DATA_WIDTH = 8,     // Width of data bus
    parameter MUX_DEPTH  = 4      // Number of inputs
) (
    input  wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0], // Input array
    input  wire [$clog2(MUX_DEPTH)-1:0] select,           // Selection bits
    input  wire                         clk,              // Clock for pipelining
    input  wire                         rst_n,            // Active-low reset
    output wire [DATA_WIDTH-1:0]        data_out          // Selected output
);

    // Stage 1: Register input data and select signal for clear dataflow
    reg  [DATA_WIDTH-1:0] stage1_data_in [MUX_DEPTH-1:0];
    reg  [$clog2(MUX_DEPTH)-1:0] stage1_select;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < MUX_DEPTH; i = i + 1)
                stage1_data_in[i] <= {DATA_WIDTH{1'b0}};
            stage1_select <= {$clog2(MUX_DEPTH){1'b0}};
        end else begin
            for (i = 0; i < MUX_DEPTH; i = i + 1)
                stage1_data_in[i] <= data_in[i];
            stage1_select <= select;
        end
    end

    // Stage 2: Pipelined multiplexer core
    wire [DATA_WIDTH-1:0] stage2_mux_out;

    param_mux_pipelined_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .MUX_DEPTH(MUX_DEPTH)
    ) u_param_mux_pipelined_core (
        .pipe_data_in(stage1_data_in),
        .pipe_select(stage1_select),
        .clk(clk),
        .rst_n(rst_n),
        .pipe_data_out(stage2_mux_out)
    );

    // Stage 3: Output register for timing closure and clear data flow
    reg [DATA_WIDTH-1:0] stage3_data_out;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_data_out <= {DATA_WIDTH{1'b0}};
        else
            stage3_data_out <= stage2_mux_out;
    end

    assign data_out = stage3_data_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: param_mux_pipelined_core
// Function: Implements parameterizable pipelined N-to-1 multiplexer logic
// -----------------------------------------------------------------------------
module param_mux_pipelined_core #(
    parameter DATA_WIDTH = 8,     // Width of data bus
    parameter MUX_DEPTH  = 4      // Number of inputs
) (
    input  wire [DATA_WIDTH-1:0] pipe_data_in [MUX_DEPTH-1:0], // Input array
    input  wire [$clog2(MUX_DEPTH)-1:0] pipe_select,           // Selection bits
    input  wire                         clk,                   // Clock for pipelining
    input  wire                         rst_n,                 // Active-low reset
    output wire [DATA_WIDTH-1:0]        pipe_data_out          // Selected output
);

    // Internal: register select for clear pipeline stage
    reg [$clog2(MUX_DEPTH)-1:0] sel_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_reg <= {$clog2(MUX_DEPTH){1'b0}};
        else
            sel_reg <= pipe_select;
    end

    // Internal: register input array for clear pipeline stage
    reg [DATA_WIDTH-1:0] data_reg [MUX_DEPTH-1:0];
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (j = 0; j < MUX_DEPTH; j = j + 1)
                data_reg[j] <= {DATA_WIDTH{1'b0}};
        else
            for (j = 0; j < MUX_DEPTH; j = j + 1)
                data_reg[j] <= pipe_data_in[j];
    end

    // Combinational selection using pipelined registers
    assign pipe_data_out = data_reg[sel_reg];

endmodule