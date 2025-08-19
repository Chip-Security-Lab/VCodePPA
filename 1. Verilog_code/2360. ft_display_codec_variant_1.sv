//SystemVerilog
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
    
    // Registered signals and combinational wires
    reg [23:0] rgb_in_reg;
    reg data_valid_reg;
    reg ecc_enable_reg;
    wire [15:0] rgb565_wire;
    wire [3:0] ecc_bits_wire;
    wire [3:0] syndrome_wire;
    wire [15:0] corrected_rgb565;
    
    // RGB conversion and ECC calculation
    assign rgb565_wire = {rgb_in_reg[23:19], rgb_in_reg[15:10], rgb_in_reg[7:3]};
    assign ecc_bits_wire = gen_hamming(rgb565_wire);
    assign syndrome_wire = ecc_bits_wire ^ gen_hamming(rgb565_wire);
    assign corrected_rgb565 = correct_error(rgb565_wire, syndrome_wire);
    
    // Flattened sequential logic block for inputs and outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            rgb_in_reg <= 24'h000000;
            data_valid_reg <= 1'b0;
            ecc_enable_reg <= 1'b0;
            protected_out <= 20'h00000;
            error_detected <= 1'b0;
            rgb565_out <= 16'h0000;
        end else begin
            // Register inputs
            rgb_in_reg <= rgb_in;
            data_valid_reg <= data_valid;
            ecc_enable_reg <= ecc_enable;
            
            // Flattened output logic - process with ECC enabled
            if (data_valid_reg && ecc_enable_reg) begin
                protected_out <= {rgb565_wire, ecc_bits_wire};
                error_detected <= (syndrome_wire != 4'h0);
                rgb565_out <= corrected_rgb565;
            end
            
            // Flattened output logic - process without ECC
            if (data_valid_reg && !ecc_enable_reg) begin
                protected_out <= {rgb565_wire, 4'h0};
                error_detected <= 1'b0;
                rgb565_out <= rgb565_wire;
            end
        end
    end
endmodule