//SystemVerilog
// Top-level module for Gray code to Binary code conversion
module gray_to_bin #(
    parameter DATA_W = 8
)(
    input  [DATA_W-1:0] gray_code,
    output [DATA_W-1:0] binary
);

    // Internal signal for holding the result of the conversion
    wire [DATA_W-1:0] bin_internal;

    // Submodule instance: Gray to Binary conversion logic
    gray_to_bin_logic #(
        .DATA_W(DATA_W)
    ) u_gray_to_bin_logic (
        .gray_code_in(gray_code),
        .binary_out(bin_internal)
    );

    // Output assignment
    assign binary = bin_internal;

endmodule

// -----------------------------------------------------------------------------
// gray_to_bin_logic
// Description:
//   Performs combinational Gray code to Binary code conversion.
//   DATA_W is the width of the code.
// -----------------------------------------------------------------------------
module gray_to_bin_logic #(
    parameter DATA_W = 8
)(
    input  [DATA_W-1:0] gray_code_in,
    output [DATA_W-1:0] binary_out
);

    integer idx;
    reg [DATA_W-1:0] bin_temp;

    always @(*) begin
        bin_temp[DATA_W-1] = gray_code_in[DATA_W-1];
        idx = DATA_W-2;
        while (idx >= 0) begin
            bin_temp[idx] = bin_temp[idx+1] ^ gray_code_in[idx];
            idx = idx - 1;
        end
    end

    assign binary_out = bin_temp;

endmodule