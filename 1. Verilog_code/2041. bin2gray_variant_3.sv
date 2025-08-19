//SystemVerilog
module bin2gray #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    wire [WIDTH-1:0] shifted_bin;
    wire [WIDTH-1:0] inverted_shifted_bin;
    reg  [WIDTH-1:0] effective_shifted_bin;
    reg  [WIDTH-1:0] gray_out_reg;

    assign shifted_bin = bin_in >> 1;
    assign inverted_shifted_bin = ~shifted_bin;

    always @(*) begin
        if (bin_in[WIDTH-1]) begin
            effective_shifted_bin = inverted_shifted_bin;
        end else begin
            effective_shifted_bin = shifted_bin;
        end
    end

    always @(*) begin
        gray_out_reg = bin_in ^ effective_shifted_bin;
    end

    assign gray_out = gray_out_reg;
endmodule