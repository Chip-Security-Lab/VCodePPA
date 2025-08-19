//SystemVerilog
module fraction_to_integer #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_in,
    output reg  [INT_WIDTH-1:0]          int_out
);

    // Stage 1: Extract integer and rounding bit from input
    reg [INT_WIDTH-1:0] integer_stage1;
    reg                 rounding_bit_stage1;

    // Stage 2: Pipeline registers for integer and rounding bit
    reg [INT_WIDTH-1:0] integer_stage2;
    reg                 rounding_bit_stage2;

    // Stage 3: Output register for rounded integer
    reg [INT_WIDTH-1:0] rounded_integer_stage3;

    // Stage 1: Combinational extraction of integer and rounding bit
    always @(*) begin
        integer_stage1      = frac_in[INT_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
        rounding_bit_stage1 = frac_in[FRAC_WIDTH-1];
    end

    // Stage 2: Register the extracted values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer_stage2      <= {INT_WIDTH{1'b0}};
            rounding_bit_stage2 <= 1'b0;
        end else begin
            integer_stage2      <= integer_stage1;
            rounding_bit_stage2 <= rounding_bit_stage1;
        end
    end

    // Stage 3: Register the rounded integer result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rounded_integer_stage3 <= {INT_WIDTH{1'b0}};
        end else begin
            rounded_integer_stage3 <= integer_stage2 + rounding_bit_stage2;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {INT_WIDTH{1'b0}};
        end else begin
            int_out <= rounded_integer_stage3;
        end
    end

endmodule