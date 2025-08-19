module ft_display_codec (
    input clk, rst_n,
    input [23:0] rgb_in,
    input data_valid,
    input ecc_enable,
    output reg [19:0] protected_out,  // 16-bit data + 4-bit Hamming code
    output reg error_detected,
    output reg [15:0] rgb565_out
);
    // Hamming code generation function (simplified)
    function [3:0] gen_hamming;
        input [15:0] data;
        begin
            gen_hamming[0] = ^{data[0], data[1], data[3], data[4], data[6], data[8], data[10], data[11], data[13], data[15]};
            gen_hamming[1] = ^{data[0], data[2], data[3], data[5], data[6], data[9], data[10], data[12], data[13]};
            gen_hamming[2] = ^{data[1], data[2], data[3], data[7], data[8], data[9], data[10], data[14], data[15]};
            gen_hamming[3] = ^{data[4], data[5], data[6], data[7], data[8], data[9], data[10]};
        end
    endfunction
    
    // Error correction function (simplified)
    function [15:0] correct_error;
        input [15:0] data;
        input [3:0] syndrome;
        reg [15:0] result;
        begin
            result = data;
            case (syndrome)
                4'h1: result[0] = ~data[0];
                4'h2: result[1] = ~data[1];
                4'h3: result[2] = ~data[2];
                4'h4: result[3] = ~data[3];
                4'h5: result[4] = ~data[4];
                4'h6: result[5] = ~data[5];
                4'h7: result[6] = ~data[6];
                4'h8: result[7] = ~data[7];
                4'h9: result[8] = ~data[8];
                4'hA: result[9] = ~data[9];
                4'hB: result[10] = ~data[10];
                4'hC: result[11] = ~data[11];
                4'hD: result[12] = ~data[12];
                4'hE: result[13] = ~data[13];
                4'hF: result[14] = ~data[14];
                // Default case handles no error or double error
            endcase
            correct_error = result;
        end
    endfunction
    
    // RGB conversion and ECC logic
    reg [15:0] rgb565;
    reg [3:0] ecc_bits;
    reg [3:0] syndrome;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565 <= 16'h0000;
            ecc_bits <= 4'h0;
            protected_out <= 20'h00000;
            error_detected <= 1'b0;
            rgb565_out <= 16'h0000;
            syndrome <= 4'h0;
        end else if (data_valid) begin
            // RGB888 to RGB565 conversion
            rgb565 <= {rgb_in[23:19], rgb_in[15:10], rgb_in[7:3]};
            
            // Generate ECC bits if enabled
            if (ecc_enable) begin
                ecc_bits <= gen_hamming(rgb565);
                protected_out <= {rgb565, ecc_bits};
                
                // Error detection and correction
                syndrome <= ecc_bits ^ gen_hamming(rgb565);
                error_detected <= (syndrome != 4'h0);
                rgb565_out <= correct_error(rgb565, syndrome);
            end else begin
                // Bypass ECC
                protected_out <= {rgb565, 4'h0};
                error_detected <= 1'b0;
                rgb565_out <= rgb565;
            end
        end
    end
endmodule