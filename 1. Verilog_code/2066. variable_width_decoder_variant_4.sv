//SystemVerilog
// Top-level variable width decoder with hierarchical structure

module variable_width_decoder #(
    parameter IN_WIDTH = 3,
    parameter OUT_SEL = 2
) (
    input  wire [IN_WIDTH-1:0] encoded_in,
    input  wire [OUT_SEL-1:0]  width_sel,
    output reg  [(2**IN_WIDTH)-1:0] decoded_out
);

    // Internal signals
    wire [(2**IN_WIDTH)-1:0] decoded_out_case0;
    wire [(2**IN_WIDTH)-1:0] decoded_out_case1;
    wire [(2**IN_WIDTH)-1:0] decoded_out_case2;
    wire [(2**IN_WIDTH)-1:0] decoded_out_case3;

    // Submodule instantiations

    // Case 0: width_sel == 0, 1-hot decode on lowest bit
    decode_case0 #(
        .IN_WIDTH(IN_WIDTH)
    ) u_decode_case0 (
        .encoded_in(encoded_in),
        .decoded_out(decoded_out_case0)
    );

    // Case 1: width_sel == 1, 1-hot decode on lowest 2 bits
    decode_case1 #(
        .IN_WIDTH(IN_WIDTH)
    ) u_decode_case1 (
        .encoded_in(encoded_in),
        .decoded_out(decoded_out_case1)
    );

    // Case 2: width_sel == 2, 1-hot decode on lowest 3 bits
    decode_case2 #(
        .IN_WIDTH(IN_WIDTH)
    ) u_decode_case2 (
        .encoded_in(encoded_in),
        .decoded_out(decoded_out_case2)
    );

    // Case 3: width_sel == 3, full-width decode using conditional sum subtractor
    decode_case3 #(
        .IN_WIDTH(IN_WIDTH)
    ) u_decode_case3 (
        .encoded_in(encoded_in),
        .decoded_out(decoded_out_case3)
    );

    // Output select logic
    always @(*) begin
        case (width_sel)
            2'd0: decoded_out = decoded_out_case0;
            2'd1: decoded_out = decoded_out_case1;
            2'd2: decoded_out = decoded_out_case2;
            2'd3: decoded_out = decoded_out_case3;
            default: decoded_out = {(2**IN_WIDTH){1'b0}};
        endcase
    end

endmodule

//------------------------------------------------------------------------------
// Submodule: decode_case0
// 1-hot decode on LSB of encoded_in
//------------------------------------------------------------------------------
module decode_case0 #(
    parameter IN_WIDTH = 3
) (
    input  wire [IN_WIDTH-1:0] encoded_in,
    output reg  [(2**IN_WIDTH)-1:0] decoded_out
);
    integer i;
    always @(*) begin
        decoded_out = {(2**IN_WIDTH){1'b0}};
        decoded_out[{4'd0, encoded_in[0]}] = 1'b1;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: decode_case1
// 1-hot decode on LSB 2 bits of encoded_in
//------------------------------------------------------------------------------
module decode_case1 #(
    parameter IN_WIDTH = 3
) (
    input  wire [IN_WIDTH-1:0] encoded_in,
    output reg  [(2**IN_WIDTH)-1:0] decoded_out
);
    integer i;
    always @(*) begin
        decoded_out = {(2**IN_WIDTH){1'b0}};
        decoded_out[{3'd0, encoded_in[1:0]}] = 1'b1;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: decode_case2
// 1-hot decode on LSB 3 bits of encoded_in
//------------------------------------------------------------------------------
module decode_case2 #(
    parameter IN_WIDTH = 3
) (
    input  wire [IN_WIDTH-1:0] encoded_in,
    output reg  [(2**IN_WIDTH)-1:0] decoded_out
);
    integer i;
    always @(*) begin
        decoded_out = {(2**IN_WIDTH){1'b0}};
        decoded_out[{2'd0, encoded_in[2:0]}] = 1'b1;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: decode_case3
// Full-width decode using conditional sum subtractor for index comparison
//------------------------------------------------------------------------------
module decode_case3 #(
    parameter IN_WIDTH = 3
) (
    input  wire [IN_WIDTH-1:0] encoded_in,
    output reg  [(2**IN_WIDTH)-1:0] decoded_out
);
    integer k;
    wire [4:0] encoded_in_ext;

    assign encoded_in_ext = { {(5-IN_WIDTH){1'b0}}, encoded_in };

    function [4:0] conditional_sum_sub_5bit;
        input [4:0] a;
        input [4:0] b;
        reg [4:0] b_xor;
        reg [4:0] sum0;
        reg [4:0] carry0;
        integer i;
        begin
            b_xor = b ^ 5'b11111; // invert b for subtraction
            sum0[0] = a[0] ^ b_xor[0] ^ 1'b1; // Cin = 1 for subtractor
            carry0[0] = (a[0] & b_xor[0]) | (a[0] & 1'b1) | (b_xor[0] & 1'b1);
            for (i = 1; i < 5; i = i + 1) begin
                sum0[i] = a[i] ^ b_xor[i] ^ carry0[i-1];
                carry0[i] = (a[i] & b_xor[i]) | (a[i] & carry0[i-1]) | (b_xor[i] & carry0[i-1]);
            end
            conditional_sum_sub_5bit = sum0;
        end
    endfunction

    always @(*) begin
        decoded_out = {(2**IN_WIDTH){1'b0}};
        for (k = 0; k < (2**IN_WIDTH); k = k + 1) begin
            if (conditional_sum_sub_5bit(encoded_in_ext, { {(5-IN_WIDTH){1'b0}}, k }) == 5'd0)
                decoded_out[k] = 1'b1;
            else
                decoded_out[k] = 1'b0;
        end
    end
endmodule