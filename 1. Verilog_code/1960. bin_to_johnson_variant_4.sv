//SystemVerilog
// Top-level module: bin_to_johnson_pipeline
// Hierarchical & Pipelined design: structured dataflow with pipeline registers for clarity and timing

module bin_to_johnson_pipeline #(
    parameter WIDTH = 4
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [WIDTH-1:0]          bin_in,
    output wire [2*WIDTH-1:0]        johnson_out
);

    // Stage 1: Position calculation
    wire [$clog2(2*WIDTH):0]         pos_stage1;
    reg  [$clog2(2*WIDTH):0]         pos_stage2;

    // Stage 2: Pattern generation
    wire [2*WIDTH-1:0]               pattern_stage2;
    reg  [2*WIDTH-1:0]               pattern_stage3;

    // Stage 3: Inversion control
    wire                             invert_stage3;
    reg                              invert_stage4;

    // Stage 4: Output select
    wire [2*WIDTH-1:0]               johnson_out_stage4;

    // Pipeline register: Stage 1 to Stage 2 (pos)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pos_stage2 <= {($clog2(2*WIDTH)+1){1'b0}};
        else
            pos_stage2 <= pos_stage1;
    end

    // Pipeline register: Stage 2 to Stage 3 (pattern)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pattern_stage3 <= {2*WIDTH{1'b0}};
        else
            pattern_stage3 <= pattern_stage2;
    end

    // Pipeline register: Stage 3 to Stage 4 (invert)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            invert_stage4 <= 1'b0;
        else
            invert_stage4 <= invert_stage3;
    end

    // Submodule: Position Calculator (Stage 1)
    bin_to_johnson_pos_calc #(
        .WIDTH(WIDTH)
    ) u_pos_calc (
        .bin_in   (bin_in),
        .pos      (pos_stage1)
    );

    // Submodule: Pattern Generator (Stage 2)
    bin_to_johnson_pattern_gen #(
        .WIDTH(WIDTH)
    ) u_pattern_gen (
        .clk      (clk),
        .rst_n    (rst_n),
        .pos      (pos_stage2),
        .pattern  (pattern_stage2)
    );

    // Submodule: Inversion Control (Stage 3)
    bin_to_johnson_invert_ctrl #(
        .WIDTH(WIDTH)
    ) u_invert_ctrl (
        .pos      (pos_stage2),
        .invert   (invert_stage3)
    );

    // Submodule: Output Selector (Stage 4)
    bin_to_johnson_output_sel #(
        .WIDTH(WIDTH)
    ) u_output_sel (
        .pattern      (pattern_stage3),
        .invert       (invert_stage4),
        .johnson_out  (johnson_out_stage4)
    );

    // Output register (optional for timing closure and clarity)
    reg [2*WIDTH-1:0] johnson_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            johnson_out_reg <= {2*WIDTH{1'b0}};
        else
            johnson_out_reg <= johnson_out_stage4;
    end

    assign johnson_out = johnson_out_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_johnson_pos_calc
// Function: Computes the Johnson code position as bin_in modulo (2*WIDTH)
// -----------------------------------------------------------------------------
module bin_to_johnson_pos_calc #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0]              bin_in,
    output wire [$clog2(2*WIDTH):0]      pos
);
    assign pos = bin_in % (2*WIDTH);
endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_johnson_pattern_gen
// Function: Generates the Johnson pattern with 'pos' bits set to 1
// Pipeline input: pos, Pipeline output: pattern
// -----------------------------------------------------------------------------
module bin_to_johnson_pattern_gen #(
    parameter WIDTH = 4
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [$clog2(2*WIDTH):0]      pos,
    output reg  [2*WIDTH-1:0]            pattern
);
    integer i;
    reg [2*WIDTH-1:0] pattern_comb;
    always @(*) begin
        pattern_comb = {2*WIDTH{1'b0}};
        for (i = 0; i < 2*WIDTH; i = i + 1)
            pattern_comb[i] = (i < pos) ? 1'b1 : 1'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pattern <= {2*WIDTH{1'b0}};
        else
            pattern <= pattern_comb;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_johnson_invert_ctrl
// Function: Determines if the output pattern should be inverted (pos > WIDTH)
// -----------------------------------------------------------------------------
module bin_to_johnson_invert_ctrl #(
    parameter WIDTH = 4
)(
    input  wire [$clog2(2*WIDTH):0]      pos,
    output wire                          invert
);
    assign invert = (pos > WIDTH) ? 1'b1 : 1'b0;
endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_johnson_output_sel
// Function: Outputs either the pattern or its bitwise inversion based on 'invert'
// -----------------------------------------------------------------------------
module bin_to_johnson_output_sel #(
    parameter WIDTH = 4
)(
    input  wire [2*WIDTH-1:0]            pattern,
    input  wire                          invert,
    output wire [2*WIDTH-1:0]            johnson_out
);
    assign johnson_out = invert ? ~pattern : pattern;
endmodule