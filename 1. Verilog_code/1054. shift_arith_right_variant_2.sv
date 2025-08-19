//SystemVerilog
module shift_arith_right #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0]       shift_amount,
    output reg [WIDTH-1:0] data_out
);

    // 3-bit Parallel Borrow Lookahead Subtractor
    function [2:0] borrow_lookahead_sub;
        input [2:0] a, b;
        input       cin;
        reg   [2:0] diff;
        reg   [2:0] gen, prop;
        reg   [3:0] borrow;
        integer     i;
        begin
            // Generate and Propagate for borrow
            for (i = 0; i < 3; i = i + 1) begin
                gen[i]  = (~a[i]) & b[i];
                prop[i] = (~(a[i] ^ b[i]));
            end
            // Borrow chain
            borrow[0] = cin;
            borrow[1] = gen[0] | (prop[0] & borrow[0]);
            borrow[2] = gen[1] | (prop[1] & borrow[1]);
            borrow[3] = gen[2] | (prop[2] & borrow[2]);
            // Difference
            for (i = 0; i < 3; i = i + 1) begin
                diff[i] = a[i] ^ b[i] ^ borrow[i];
            end
            borrow_lookahead_sub = diff;
        end
    endfunction

    reg [WIDTH-1:0] arith_result [0:3];
    integer idx;

    always @* begin
        arith_result[0] = data_in;
        // Shift by 1 with sign extension
        arith_result[1][WIDTH-1] = data_in[WIDTH-1];
        for (idx = WIDTH-2; idx >= 0; idx = idx - 1) begin
            arith_result[1][idx] = data_in[idx+1];
        end
        // Shift by 2 with sign extension
        arith_result[2][WIDTH-1:WIDTH-2] = {data_in[WIDTH-1], data_in[WIDTH-1]};
        for (idx = WIDTH-3; idx >= 0; idx = idx - 1) begin
            arith_result[2][idx] = data_in[idx+2];
        end
        // Shift by 3 with sign extension
        arith_result[3][WIDTH-1:WIDTH-3] = {data_in[WIDTH-1], data_in[WIDTH-1], data_in[WIDTH-1]};
        for (idx = WIDTH-4; idx >= 0; idx = idx - 1) begin
            arith_result[3][idx] = data_in[idx+3];
        end

        // Replacing case with if-else if
        if (shift_amount == 3'd0) begin
            data_out = arith_result[0];
        end else if (shift_amount == 3'd1) begin
            data_out = arith_result[1];
        end else if (shift_amount == 3'd2) begin
            data_out = arith_result[2];
        end else if (shift_amount == 3'd3) begin
            data_out = arith_result[3];
        end else begin
            for (idx = 0; idx < WIDTH; idx = idx + 1)
                data_out[idx] = data_in[WIDTH-1];
        end
    end

endmodule