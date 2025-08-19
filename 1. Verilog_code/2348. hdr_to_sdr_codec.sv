module hdr_to_sdr_codec (
    input [15:0] hdr_pixel,
    input [1:0] method_sel,  // 0: Linear, 1: Log, 2: Exp, 3: Custom
    input [7:0] custom_param,
    output reg [7:0] sdr_pixel
);
    reg [7:0] log_result;
    reg [3:0] bit_pos;
    reg found;
    
    // Improved log2 approximation calculation
    always @(*) begin
        log_result = 0;
        bit_pos = 0;
        found = 0;
        
        // Priority encoder approach
        if (!found && hdr_pixel[15]) begin bit_pos = 4'd15; found = 1; end
        else if (!found && hdr_pixel[14]) begin bit_pos = 4'd14; found = 1; end
        else if (!found && hdr_pixel[13]) begin bit_pos = 4'd13; found = 1; end
        else if (!found && hdr_pixel[12]) begin bit_pos = 4'd12; found = 1; end
        else if (!found && hdr_pixel[11]) begin bit_pos = 4'd11; found = 1; end
        else if (!found && hdr_pixel[10]) begin bit_pos = 4'd10; found = 1; end
        else if (!found && hdr_pixel[9]) begin bit_pos = 4'd9; found = 1; end
        else if (!found && hdr_pixel[8]) begin bit_pos = 4'd8; found = 1; end
        else if (!found && hdr_pixel[7]) begin bit_pos = 4'd7; found = 1; end
        else if (!found && hdr_pixel[6]) begin bit_pos = 4'd6; found = 1; end
        else if (!found && hdr_pixel[5]) begin bit_pos = 4'd5; found = 1; end
        else if (!found && hdr_pixel[4]) begin bit_pos = 4'd4; found = 1; end
        else if (!found && hdr_pixel[3]) begin bit_pos = 4'd3; found = 1; end
        else if (!found && hdr_pixel[2]) begin bit_pos = 4'd2; found = 1; end
        else if (!found && hdr_pixel[1]) begin bit_pos = 4'd1; found = 1; end
        else if (!found && hdr_pixel[0]) begin bit_pos = 4'd0; found = 1; end
        
        log_result = {bit_pos, 4'b0};
    end
    
    always @(*) begin
        case (method_sel)
            2'b00: sdr_pixel = hdr_pixel >> 8;  // Simple linear truncation
            2'b01: sdr_pixel = log_result;  // Log approximation
            2'b10: sdr_pixel = (hdr_pixel > 16'h00FF) ? 8'hFF : hdr_pixel[7:0]; // Clipping
            2'b11: sdr_pixel = ((hdr_pixel * custom_param) >> 8); // Custom scaling
            default: sdr_pixel = hdr_pixel[7:0];
        endcase
    end
endmodule