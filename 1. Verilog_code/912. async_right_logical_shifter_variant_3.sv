//SystemVerilog
module async_right_logical_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);

    // Optimized implementation using barrel shifter approach
    wire [WIDTH-1:0] shift_stages [$clog2(WIDTH):0];
    genvar i;
    
    // First stage is input data
    assign shift_stages[0] = in_data;
    
    // Generate barrel shifter stages
    generate
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin : gen_shifter
            assign shift_stages[i+1] = shift_amt[i] ? 
                {{(1<<i){1'b0}}, shift_stages[i][WIDTH-1:(1<<i)]} : 
                shift_stages[i];
        end
    endgenerate
    
    // Final output assignment
    assign out_data = shift_stages[$clog2(WIDTH)];

    // synthesis translate_off
    initial begin
        $display("Optimized Async Right Logical Shifter, Width=%0d", WIDTH);
    end
    // synthesis translate_on

endmodule