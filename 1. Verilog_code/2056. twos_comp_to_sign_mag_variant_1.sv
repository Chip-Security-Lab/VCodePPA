//SystemVerilog
module twos_comp_to_sign_mag #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      twos_comp_in,
    output wire [WIDTH-1:0]      sign_mag_out
);

    // Stage 1: Extract sign and magnitude
    reg                     stage1_sign;
    reg [WIDTH-2:0]         stage1_magnitude;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_sign      <= 1'b0;
            stage1_magnitude <= {WIDTH-1{1'b0}};
        end else begin
            stage1_sign      <= twos_comp_in[WIDTH-1];
            stage1_magnitude <= twos_comp_in[WIDTH-2:0];
        end
    end

    // Stage 2: Conditional magnitude conversion (negation if negative)
    reg [WIDTH-2:0]         stage2_magnitude;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_magnitude <= {WIDTH-1{1'b0}};
        end else begin
            if (stage1_sign) begin
                stage2_magnitude <= (~stage1_magnitude) + 1'b1;
            end else begin
                stage2_magnitude <= stage1_magnitude;
            end
        end
    end

    // Stage 3: Output construction
    reg [WIDTH-1:0]         stage3_sign_mag_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_sign_mag_out <= {WIDTH{1'b0}};
        end else begin
            stage3_sign_mag_out <= {stage1_sign, stage2_magnitude};
        end
    end

    assign sign_mag_out = stage3_sign_mag_out;

endmodule