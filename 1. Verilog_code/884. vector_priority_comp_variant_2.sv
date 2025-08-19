//SystemVerilog
module vector_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    input [WIDTH-1:0] priority_mask,
    output [$clog2(WIDTH)-1:0] encoded_position,
    output valid_output
);

    // LUT-based priority encoder
    reg [2:0] lut_encoded_pos;
    reg lut_valid;
    
    // LUT for 8-bit priority encoding
    always @(*) begin
        casez (data_vector & priority_mask)
            8'b1???????: begin lut_encoded_pos = 3'd7; lut_valid = 1'b1; end
            8'b01??????: begin lut_encoded_pos = 3'd6; lut_valid = 1'b1; end
            8'b001?????: begin lut_encoded_pos = 3'd5; lut_valid = 1'b1; end
            8'b0001????: begin lut_encoded_pos = 3'd4; lut_valid = 1'b1; end
            8'b00001???: begin lut_encoded_pos = 3'd3; lut_valid = 1'b1; end
            8'b000001??: begin lut_encoded_pos = 3'd2; lut_valid = 1'b1; end
            8'b0000001?: begin lut_encoded_pos = 3'd1; lut_valid = 1'b1; end
            8'b00000001: begin lut_encoded_pos = 3'd0; lut_valid = 1'b1; end
            default: begin lut_encoded_pos = 3'd0; lut_valid = 1'b0; end
        endcase
    end

    assign encoded_position = lut_encoded_pos;
    assign valid_output = lut_valid;

endmodule