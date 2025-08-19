//SystemVerilog
// Top-level module
module crc_with_masking(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] mask,
    input wire data_valid,
    output wire [7:0] crc
);
    // Internal signals
    wire [7:0] masked_data;
    
    // Instantiate data masking module
    data_masking_unit mask_unit (
        .data(data),
        .mask(mask),
        .masked_data(masked_data)
    );
    
    // Instantiate CRC calculation module
    crc_calculation_unit #(
        .POLY(8'h07)
    ) crc_unit (
        .clk(clk),
        .rst(rst),
        .data_in(masked_data),
        .data_valid(data_valid),
        .crc_out(crc)
    );
endmodule

// Data masking module
module data_masking_unit(
    input wire [7:0] data,
    input wire [7:0] mask,
    output wire [7:0] masked_data
);
    // Apply mask to input data
    assign masked_data = data & mask;
endmodule

// CRC calculation module
module crc_calculation_unit #(
    parameter [7:0] POLY = 8'h07
)(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] crc_out
);
    // CRC calculation with polynomial division
    wire crc_feedback = crc_out[7] ^ data_in[0];
    
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 8'h00;
        end else if (data_valid) begin
            crc_out <= {crc_out[6:0], 1'b0} ^ (crc_feedback ? POLY : 8'h00);
        end
    end
endmodule