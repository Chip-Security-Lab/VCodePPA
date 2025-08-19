//SystemVerilog
// Top-level module: q_format_converter_15_to_31_pipelined
module q_format_converter_15_to_31_pipelined(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [15:0]  q15_data_in,
    input  wire         q15_valid_in,
    output wire [31:0]  q31_data_out,
    output wire         q31_valid_out
);

    // Stage 1: Extract sign and magnitude (combinational)
    wire        comb_sign;
    wire [14:0] comb_magnitude;
    wire        comb_valid;

    assign comb_sign      = q15_data_in[15];
    assign comb_magnitude = q15_data_in[14:0];
    assign comb_valid     = q15_valid_in;

    // Stage 2: Register outputs of combinational logic after packing into Q31
    reg [31:0] stage2_q31_data;
    reg        stage2_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_q31_data <= 32'b0;
            stage2_valid    <= 1'b0;
        end else begin
            stage2_q31_data <= {comb_sign, comb_magnitude, 16'b0};
            stage2_valid    <= comb_valid;
        end
    end

    assign q31_data_out  = stage2_q31_data;
    assign q31_valid_out = stage2_valid;

endmodule