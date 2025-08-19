//SystemVerilog
///////////////////////////////////////////////////////////
// Module: hdr_to_sdr_codec                             //
// Top level module for HDR to SDR conversion         //
/////////////////////////////////////////////////////////
module hdr_to_sdr_codec (
    input [15:0] hdr_pixel,
    input [1:0] method_sel,  // 0: Linear, 1: Log, 2: Exp, 3: Custom
    input [7:0] custom_param,
    output reg [7:0] sdr_pixel
);
    // Internal signals
    wire [7:0] log_result;
    
    // Priority encoder for log approximation
    priority_encoder #(
        .WIDTH(16),
        .OUTPUT_WIDTH(4)
    ) log_encoder (
        .data_in(hdr_pixel),
        .bit_pos(log_result[7:4]),
        .valid()
    );
    
    // Fixed lower 4 bits
    assign log_result[3:0] = 4'b0000;
    
    // Method selection logic
    always @(*) begin
        case (method_sel)
            2'b00: sdr_pixel = hdr_pixel >> 8;  // Simple linear truncation
            2'b01: sdr_pixel = log_result;      // Log approximation
            2'b10: sdr_pixel = (hdr_pixel > 16'h00FF) ? 8'hFF : hdr_pixel[7:0]; // Clipping
            2'b11: sdr_pixel = ((hdr_pixel * custom_param) >> 8); // Custom scaling
            default: sdr_pixel = hdr_pixel[7:0];
        endcase
    end
endmodule

///////////////////////////////////////////////////////////
// Module: priority_encoder                             //
// Generalized priority encoder with parameterized     //
// width for finding the most significant '1' bit      //
/////////////////////////////////////////////////////////
module priority_encoder #(
    parameter WIDTH = 16,
    parameter OUTPUT_WIDTH = 4
)(
    input [WIDTH-1:0] data_in,
    output reg [OUTPUT_WIDTH-1:0] bit_pos,
    output reg valid
);
    integer i;
    
    always @(*) begin
        bit_pos = {OUTPUT_WIDTH{1'b0}};
        valid = 1'b0;
        
        // Find the most significant '1' bit using a for loop
        // This is more efficient and scalable than the if-else chain
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (data_in[i] && !valid) begin
                bit_pos = i[OUTPUT_WIDTH-1:0];
                valid = 1'b1;
            end
        end
    end
endmodule