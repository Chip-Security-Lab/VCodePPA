//SystemVerilog
// Top-level module: Two's Complement to Sign-Magnitude Converter (Pipelined, Structured Data Path)
module twos_comp_to_sign_mag #(parameter WIDTH=16)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [WIDTH-1:0]         twos_comp_in,
    output wire [WIDTH-1:0]         sign_mag_out
);

    // Pipeline Stage 1: Extract sign and magnitude
    wire                            stage1_sign_bit;
    wire [WIDTH-2:0]                stage1_magnitude;
    reg                             stage1_sign_bit_reg;
    reg  [WIDTH-2:0]                stage1_magnitude_reg;

    sign_extract #(.WIDTH(WIDTH)) u_sign_extract (
        .data_in          (twos_comp_in),
        .sign_bit         (stage1_sign_bit),
        .magnitude_in     (stage1_magnitude)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_sign_bit_reg   <= 1'b0;
            stage1_magnitude_reg  <= {WIDTH-1{1'b0}};
        end else begin
            stage1_sign_bit_reg   <= stage1_sign_bit;
            stage1_magnitude_reg  <= stage1_magnitude;
        end
    end

    // Pipeline Stage 2: Magnitude Conversion
    wire [WIDTH-2:0]                stage2_magnitude;
    reg  [WIDTH-2:0]                stage2_magnitude_reg;
    reg                             stage2_sign_bit_reg;

    magnitude_convert #(.WIDTH(WIDTH)) u_magnitude_convert (
        .sign_bit        (stage1_sign_bit_reg),
        .magnitude_in    (stage1_magnitude_reg),
        .magnitude_out   (stage2_magnitude)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_magnitude_reg  <= {WIDTH-1{1'b0}};
            stage2_sign_bit_reg   <= 1'b0;
        end else begin
            stage2_magnitude_reg  <= stage2_magnitude;
            stage2_sign_bit_reg   <= stage1_sign_bit_reg;
        end
    end

    // Pipeline Stage 3: Output Register
    reg [WIDTH-1:0]                 sign_mag_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_mag_out_reg <= {WIDTH{1'b0}};
        end else begin
            sign_mag_out_reg <= {stage2_sign_bit_reg, stage2_magnitude_reg};
        end
    end

    assign sign_mag_out = sign_mag_out_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Sign Extractor
// Function: Extracts the sign bit and the magnitude bits from the input
// -----------------------------------------------------------------------------
module sign_extract #(parameter WIDTH=16)(
    input  wire [WIDTH-1:0] data_in,
    output wire             sign_bit,
    output wire [WIDTH-2:0] magnitude_in
);
    assign sign_bit     = data_in[WIDTH-1];
    assign magnitude_in = data_in[WIDTH-2:0];
endmodule

// -----------------------------------------------------------------------------
// Submodule: Magnitude Converter
// Function: Converts two's complement magnitude to sign-magnitude format
// -----------------------------------------------------------------------------
module magnitude_convert #(parameter WIDTH=16)(
    input  wire             sign_bit,
    input  wire [WIDTH-2:0] magnitude_in,
    output wire [WIDTH-2:0] magnitude_out
);
    // Reduced logic depth for magnitude conversion
    wire [WIDTH-2:0] magnitude_neg;
    assign magnitude_neg = ~magnitude_in + 1'b1;
    assign magnitude_out = sign_bit ? magnitude_neg : magnitude_in;
endmodule