//SystemVerilog
// Top-level module: range_mapper
// Function: Pipelined mapping of input value from one range to another with structured datapath

module range_mapper #(
    parameter IN_MIN  = 0, 
    parameter IN_MAX  = 1023, 
    parameter OUT_MIN = 0, 
    parameter OUT_MAX = 255
)(
    input  wire                              clk,
    input  wire                              rst_n,
    input  wire [$clog2(IN_MAX-IN_MIN+1)-1:0] in_val,
    output wire [$clog2(OUT_MAX-OUT_MIN+1)-1:0] out_val
);

    // Datapath width declarations
    localparam IN_WIDTH       = $clog2(IN_MAX-IN_MIN+1);
    localparam OUT_WIDTH      = $clog2(OUT_MAX-OUT_MIN+1);
    localparam SCALED_WIDTH   = IN_WIDTH + OUT_WIDTH;
    localparam IN_RANGE_CONST = IN_MAX - IN_MIN;
    localparam OUT_RANGE_CONST= OUT_MAX - OUT_MIN;

    // Stage 1: Input Normalization (subtract IN_MIN)
    wire [IN_WIDTH-1:0]            stage1_offset_val;
    reg  [IN_WIDTH-1:0]            stage1_offset_val_r;
    input_offset #(
        .IN_MIN(IN_MIN),
        .IN_WIDTH(IN_WIDTH)
    ) u_input_offset (
        .in_val(in_val),
        .offset_val(stage1_offset_val)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_offset_val_r <= {IN_WIDTH{1'b0}};
        else
            stage1_offset_val_r <= stage1_offset_val;
    end

    // Stage 2: Range Scaling (multiply by OUT_RANGE)
    wire [SCALED_WIDTH-1:0]        stage2_scaled_val;
    reg  [SCALED_WIDTH-1:0]        stage2_scaled_val_r;
    range_scale #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .OUT_RANGE(OUT_RANGE_CONST)
    ) u_range_scale (
        .offset_val(stage1_offset_val_r),
        .scaled_val(stage2_scaled_val)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_scaled_val_r <= {SCALED_WIDTH{1'b0}};
        else
            stage2_scaled_val_r <= stage2_scaled_val;
    end

    // Stage 3: Output Mapping (divide by IN_RANGE, add OUT_MIN)
    wire [OUT_WIDTH-1:0]           stage3_out_val;
    reg  [OUT_WIDTH-1:0]           stage3_out_val_r;
    output_map #(
        .SCALED_WIDTH(SCALED_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .IN_RANGE(IN_RANGE_CONST),
        .OUT_MIN(OUT_MIN)
    ) u_output_map (
        .scaled_val(stage2_scaled_val_r),
        .out_val(stage3_out_val)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_out_val_r <= {OUT_WIDTH{1'b0}};
        else
            stage3_out_val_r <= stage3_out_val;
    end

    // Output assignment
    assign out_val = stage3_out_val_r;

endmodule

// ---------------------------------------------------------------------------
// Submodule: input_offset
// Function: Subtracts IN_MIN from the input value to normalize to zero base
// ---------------------------------------------------------------------------

module input_offset #(
    parameter IN_MIN  = 0,
    parameter IN_WIDTH = 10
)(
    input  wire [IN_WIDTH-1:0] in_val,
    output wire [IN_WIDTH-1:0] offset_val
);
    assign offset_val = in_val - IN_MIN;
endmodule

// ---------------------------------------------------------------------------
// Submodule: range_scale
// Function: Multiplies offset value by output range
// ---------------------------------------------------------------------------

module range_scale #(
    parameter IN_WIDTH  = 10,
    parameter OUT_WIDTH = 8,
    parameter OUT_RANGE = 255
)(
    input  wire [IN_WIDTH-1:0] offset_val,
    output wire [IN_WIDTH+OUT_WIDTH-1:0] scaled_val
);
    assign scaled_val = offset_val * OUT_RANGE;
endmodule

// ---------------------------------------------------------------------------
// Submodule: output_map
// Function: Divides scaled value by input range and adds OUT_MIN
// ---------------------------------------------------------------------------

module output_map #(
    parameter SCALED_WIDTH = 18,
    parameter OUT_WIDTH    = 8,
    parameter IN_RANGE     = 1023,
    parameter OUT_MIN      = 0
)(
    input  wire [SCALED_WIDTH-1:0] scaled_val,
    output wire [OUT_WIDTH-1:0]    out_val
);
    assign out_val = (scaled_val / IN_RANGE) + OUT_MIN;
endmodule