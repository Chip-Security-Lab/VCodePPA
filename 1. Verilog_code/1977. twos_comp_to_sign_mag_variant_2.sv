//SystemVerilog
// Top-level module: Pipelined Two's Complement to Sign-Magnitude Converter (Flattened Control Flow)
module twos_comp_to_sign_mag #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      twos_comp_in,
    input  wire                  in_valid,
    output wire [WIDTH-1:0]      sign_mag_out,
    output wire                  out_valid
);

    // Stage 1: Extract sign and magnitude
    wire                        sign_stage1;
    wire [WIDTH-2:0]            magnitude_stage1;
    reg                         sign_reg_stage1;
    reg  [WIDTH-2:0]            magnitude_reg_stage1;
    reg                         valid_reg_stage1;

    assign sign_stage1      = twos_comp_in[WIDTH-1];
    assign magnitude_stage1 = twos_comp_in[WIDTH-2:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_reg_stage1      <= 1'b0;
            magnitude_reg_stage1 <= {WIDTH-1{1'b0}};
            valid_reg_stage1     <= 1'b0;
        end else if (in_valid) begin
            sign_reg_stage1      <= sign_stage1;
            magnitude_reg_stage1 <= magnitude_stage1;
            valid_reg_stage1     <= 1'b1;
        end else begin
            sign_reg_stage1      <= sign_reg_stage1;
            magnitude_reg_stage1 <= magnitude_reg_stage1;
            valid_reg_stage1     <= 1'b0;
        end
    end

    // Stage 2: Magnitude conversion (two's complement to magnitude)
    reg  [WIDTH-2:0]            abs_magnitude_reg_stage2;
    reg                         sign_reg_stage2;
    reg                         valid_reg_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_magnitude_reg_stage2 <= {WIDTH-1{1'b0}};
            sign_reg_stage2          <= 1'b0;
            valid_reg_stage2         <= 1'b0;
        end else if (valid_reg_stage1 &&  sign_reg_stage1) begin
            abs_magnitude_reg_stage2 <= (~magnitude_reg_stage1 + 1'b1);
            sign_reg_stage2          <= sign_reg_stage1;
            valid_reg_stage2         <= 1'b1;
        end else if (valid_reg_stage1 && !sign_reg_stage1) begin
            abs_magnitude_reg_stage2 <= magnitude_reg_stage1;
            sign_reg_stage2          <= sign_reg_stage1;
            valid_reg_stage2         <= 1'b1;
        end else begin
            abs_magnitude_reg_stage2 <= abs_magnitude_reg_stage2;
            sign_reg_stage2          <= sign_reg_stage2;
            valid_reg_stage2         <= 1'b0;
        end
    end

    // Stage 3: Assemble sign-magnitude output
    reg  [WIDTH-1:0]            sign_mag_out_reg;
    reg                         valid_reg_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_mag_out_reg   <= {WIDTH{1'b0}};
            valid_reg_stage3   <= 1'b0;
        end else if (valid_reg_stage2) begin
            sign_mag_out_reg   <= {sign_reg_stage2, abs_magnitude_reg_stage2};
            valid_reg_stage3   <= 1'b1;
        end else begin
            sign_mag_out_reg   <= sign_mag_out_reg;
            valid_reg_stage3   <= 1'b0;
        end
    end

    assign sign_mag_out = sign_mag_out_reg;
    assign out_valid    = valid_reg_stage3;

endmodule