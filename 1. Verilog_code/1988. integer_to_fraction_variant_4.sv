//SystemVerilog
// Top-level module: Hierarchical integer to fixed-point fraction converter (Pipelined)
module integer_to_fraction #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [INT_WIDTH-1:0]          int_in,
    input  wire [INT_WIDTH-1:0]          denominator,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_out
);

    // Stage 1: Input Registering
    reg [INT_WIDTH-1:0] int_in_stage1;
    reg [INT_WIDTH-1:0] denominator_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_in_stage1      <= {INT_WIDTH{1'b0}};
            denominator_stage1 <= {INT_WIDTH{1'b0}};
        end else begin
            int_in_stage1      <= int_in;
            denominator_stage1 <= denominator;
        end
    end

    // Stage 2: Integer Extension
    wire [INT_WIDTH+FRAC_WIDTH-1:0] extended_int_stage2;

    int_extender #(
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) u_int_extender (
        .clk(clk),
        .rst_n(rst_n),
        .int_in(int_in_stage1),
        .extended_int(extended_int_stage2)
    );

    // Stage 2: Pass denominator to next stage
    reg [INT_WIDTH-1:0] denominator_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            denominator_stage2 <= {INT_WIDTH{1'b0}};
        else
            denominator_stage2 <= denominator_stage1;
    end

    // Stage 3: Division (Fixed-point)
    wire [INT_WIDTH+FRAC_WIDTH-1:0] quotient_stage3;

    fixed_point_divider #(
        .DATA_WIDTH(INT_WIDTH+FRAC_WIDTH)
    ) u_fixed_point_divider (
        .clk(clk),
        .rst_n(rst_n),
        .numerator(extended_int_stage2),
        .denominator(denominator_stage2),
        .quotient(quotient_stage3)
    );

    // Stage 4: Output Register
    reg [INT_WIDTH+FRAC_WIDTH-1:0] frac_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            frac_out_reg <= {(INT_WIDTH+FRAC_WIDTH){1'b0}};
        else
            frac_out_reg <= quotient_stage3;
    end

    assign frac_out = frac_out_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: int_extender
// Description: Pipeline stage for extending integer input to fixed-point format.
// -----------------------------------------------------------------------------
module int_extender #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [INT_WIDTH-1:0]     int_in,
    output reg  [INT_WIDTH+FRAC_WIDTH-1:0] extended_int
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            extended_int <= {(INT_WIDTH+FRAC_WIDTH){1'b0}};
        else
            extended_int <= {int_in, {FRAC_WIDTH{1'b0}}};
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: fixed_point_divider
// Description: Pipeline stage for fixed-point division.
// -----------------------------------------------------------------------------
module fixed_point_divider #(
    parameter DATA_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [DATA_WIDTH-1:0]     numerator,
    input  wire [(DATA_WIDTH/2)-1:0] denominator,
    output reg  [DATA_WIDTH-1:0]     quotient
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            quotient <= {DATA_WIDTH{1'b0}};
        else if (denominator != 0)
            quotient <= numerator / denominator;
        else
            quotient <= {DATA_WIDTH{1'b0}};
    end
endmodule