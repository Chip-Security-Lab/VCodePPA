//SystemVerilog
module async_binary_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [$clog2(WIDTH)-1:0] encoded_output,
    output valid_output
);
    // Optimized priority encoder implementation
    reg [$clog2(WIDTH)-1:0] encoder_out;
    
    always @(*) begin
        encoder_out = 0;
        case (1'b1)
            data_vector[7]: encoder_out = 7;
            data_vector[6]: encoder_out = 6;
            data_vector[5]: encoder_out = 5;
            data_vector[4]: encoder_out = 4;
            data_vector[3]: encoder_out = 3;
            data_vector[2]: encoder_out = 2;
            data_vector[1]: encoder_out = 1;
            data_vector[0]: encoder_out = 0;
            default: encoder_out = 0;
        endcase
    end
    
    assign encoded_output = encoder_out;
    assign valid_output = |data_vector;
endmodule