//SystemVerilog
module programmable_poly_crc(
    input wire clk,
    input wire rst,
    input wire [15:0] poly_in,
    input wire poly_load,
    input wire [7:0] data,
    input wire data_valid,
    output reg [15:0] crc
);
    reg [15:0] polynomial;
    reg [7:0] data_r;
    reg data_valid_r, data_valid_r2;
    reg feedback;
    reg [15:0] pre_calculated_mask;
    reg [15:0] crc_shifted;
    reg [15:0] crc_intermediate;
    
    // Pipeline stage 1: Register inputs and calculate feedback
    always @(posedge clk) begin
        if (rst) begin
            polynomial <= 16'h1021; // Default CCITT
            data_r <= 8'h0;
            data_valid_r <= 1'b0;
            feedback <= 1'b0;
        end else begin
            if (poly_load) begin
                polynomial <= poly_in;
            end
            
            data_r <= data;
            data_valid_r <= data_valid;
            
            if (data_valid) begin
                feedback <= crc[15] ^ data[0];
            end
        end
    end
    
    // Pipeline stage 2: Calculate mask and shifted CRC
    always @(posedge clk) begin
        if (rst) begin
            pre_calculated_mask <= 16'h0000;
            crc_shifted <= 16'h0000;
            data_valid_r2 <= 1'b0;
        end else begin
            data_valid_r2 <= data_valid_r;
            
            if (data_valid_r) begin
                pre_calculated_mask <= feedback ? polynomial : 16'h0000;
                crc_shifted <= {crc[14:0], 1'b0};
            end
        end
    end
    
    // Pipeline stage 3: Final CRC calculation
    always @(posedge clk) begin
        if (rst) begin
            crc <= 16'hFFFF;
        end else if (data_valid_r2) begin
            crc <= crc_shifted ^ pre_calculated_mask;
        end
    end
endmodule