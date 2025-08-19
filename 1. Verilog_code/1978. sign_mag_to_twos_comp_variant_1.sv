//SystemVerilog
// Hierarchical Sign-magnitude to Two's Complement Converter (Pipelined & Structured Data Path)

module sign_mag_to_twos_comp #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      sign_mag_in,
    output wire [WIDTH-1:0]      twos_comp_out
);

    // Internal pipeline signals
    wire                        sign_bit_stage1;
    wire [WIDTH-2:0]            magnitude_stage1;
    wire                        sign_bit_stage2;
    wire [WIDTH-2:0]            magnitude_stage2;
    wire [WIDTH-2:0]            twos_comp_mag_stage2;
    wire                        sign_bit_stage3;
    wire [WIDTH-2:0]            magnitude_stage3;
    wire [WIDTH-2:0]            twos_comp_mag_stage3;
    wire [WIDTH-1:0]            sign_mag_stage3;
    wire [WIDTH-1:0]            twos_comp_out_stage3;

    // =========================
    // Stage 1: Field Extraction
    // =========================
    field_extract_stage #(
        .WIDTH(WIDTH)
    ) u_field_extract_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .sign_mag_in    (sign_mag_in),
        .sign_bit_out   (sign_bit_stage1),
        .magnitude_out  (magnitude_stage1)
    );

    // =========================
    // Stage 2: Magnitude Processing
    // =========================
    magnitude_process_stage #(
        .WIDTH(WIDTH-1)
    ) u_magnitude_process_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .sign_bit_in        (sign_bit_stage1),
        .magnitude_in       (magnitude_stage1),
        .sign_bit_out       (sign_bit_stage2),
        .magnitude_out      (magnitude_stage2),
        .twos_comp_mag_out  (twos_comp_mag_stage2)
    );

    // =========================
    // Stage 3: Output Compose & Selection
    // =========================
    output_select_stage #(
        .WIDTH(WIDTH)
    ) u_output_select_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .sign_bit_in        (sign_bit_stage2),
        .magnitude_in       (magnitude_stage2),
        .twos_comp_mag_in   (twos_comp_mag_stage2),
        .sign_mag_in        (sign_mag_in),
        .twos_comp_out      (twos_comp_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: field_extract_stage
// Extracts the sign bit and magnitude from sign-magnitude input and pipelines them
// -----------------------------------------------------------------------------
module field_extract_stage #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      sign_mag_in,
    output reg                   sign_bit_out,
    output reg  [WIDTH-2:0]      magnitude_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_bit_out   <= 1'b0;
            magnitude_out  <= {WIDTH-1{1'b0}};
        end else begin
            sign_bit_out   <= sign_mag_in[WIDTH-1];
            magnitude_out  <= sign_mag_in[WIDTH-2:0];
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: magnitude_process_stage
// Computes two's complement of magnitude for negative sign, pipelines values
// -----------------------------------------------------------------------------
module magnitude_process_stage #(
    parameter WIDTH = 15
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              sign_bit_in,
    input  wire [WIDTH-1:0]  magnitude_in,
    output reg               sign_bit_out,
    output reg [WIDTH-1:0]   magnitude_out,
    output reg [WIDTH-1:0]   twos_comp_mag_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_bit_out      <= 1'b0;
            magnitude_out     <= {WIDTH{1'b0}};
            twos_comp_mag_out <= {WIDTH{1'b0}};
        end else begin
            sign_bit_out      <= sign_bit_in;
            magnitude_out     <= magnitude_in;
            twos_comp_mag_out <= ~magnitude_in + 1'b1;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: output_select_stage
// Selects correct output based on sign, pipelines final result
// -----------------------------------------------------------------------------
module output_select_stage #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  sign_bit_in,
    input  wire [WIDTH-2:0]      magnitude_in,
    input  wire [WIDTH-2:0]      twos_comp_mag_in,
    input  wire [WIDTH-1:0]      sign_mag_in,
    output reg  [WIDTH-1:0]      twos_comp_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            twos_comp_out <= {WIDTH{1'b0}};
        end else begin
            twos_comp_out <= sign_bit_in ? {1'b1, twos_comp_mag_in} : sign_mag_in;
        end
    end
endmodule