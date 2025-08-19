//SystemVerilog
module bit_reverser #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     data_in,
    input                  data_in_valid,
    output [WIDTH-1:0]     data_out,
    output                 data_out_valid
);

    // Stage 1: Input Registering
    reg  [WIDTH-1:0] data_in_reg;
    reg              data_in_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg       <= {WIDTH{1'b0}};
            data_in_valid_reg <= 1'b0;
        end else begin
            data_in_reg       <= data_in;
            data_in_valid_reg <= data_in_valid;
        end
    end

    // Stage 2: Bit Reversal - Pure Combinational Logic
    wire [WIDTH-1:0] reversed_bits_comb;
    genvar gi;
    generate
        for (gi = 0; gi < WIDTH; gi = gi + 1) begin : gen_bit_reverse
            assign reversed_bits_comb[gi] = data_in_reg[WIDTH-1-gi];
        end
    endgenerate

    // Pipeline Register for reversed bits
    reg  [WIDTH-1:0] reversed_bits_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reversed_bits_reg <= {WIDTH{1'b0}};
        end else begin
            reversed_bits_reg <= reversed_bits_comb;
        end
    end

    // Stage 3: Output Registering
    reg  [WIDTH-1:0] data_out_reg;
    reg              data_out_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg       <= {WIDTH{1'b0}};
            data_out_valid_reg <= 1'b0;
        end else begin
            data_out_reg       <= reversed_bits_reg;
            data_out_valid_reg <= data_in_valid_reg;
        end
    end

    assign data_out       = data_out_reg;
    assign data_out_valid = data_out_valid_reg;

endmodule