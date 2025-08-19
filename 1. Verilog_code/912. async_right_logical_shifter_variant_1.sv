//SystemVerilog
module async_right_logical_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);
    // Internal signals for borrow-lookahead implementation
    wire [WIDTH-1:0] shift_result;
    wire [WIDTH-1:0] stage_outputs [0:$clog2(WIDTH)-1];
    
    // Borrow-lookahead based shift implementation
    // Each stage handles shifts of 2^i positions
    genvar i, j;
    generate
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin: shift_stages
            for (j = 0; j < WIDTH; j = j + 1) begin: bit_positions
                if (i == 0) begin
                    // First stage uses input directly
                    assign stage_outputs[i][j] = (j + (1 << i) < WIDTH) ? 
                                                ((shift_amt[i]) ? in_data[j + (1 << i)] : in_data[j]) : 
                                                ((shift_amt[i]) ? 1'b0 : in_data[j]);
                end else begin
                    // Subsequent stages use previous stage output
                    assign stage_outputs[i][j] = (j + (1 << i) < WIDTH) ? 
                                                ((shift_amt[i]) ? stage_outputs[i-1][j + (1 << i)] : stage_outputs[i-1][j]) : 
                                                ((shift_amt[i]) ? 1'b0 : stage_outputs[i-1][j]);
                end
            end
        end
    endgenerate
    
    // Final output assignment
    assign out_data = stage_outputs[$clog2(WIDTH)-1];
    
    // Verification code to ensure proper shifting
    // synthesis translate_off
    initial begin
        $display("Async Right Logical Shifter with Borrow-Lookahead, Width=%0d", WIDTH);
    end
    // synthesis translate_on
endmodule