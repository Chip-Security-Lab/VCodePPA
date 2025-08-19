//SystemVerilog
// Top module
module crc8_with_enable(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [7:0] data,
    output reg [7:0] crc
);
    // Intermediate signals for CRC calculation
    wire [7:0] next_crc;
    
    // Instantiate CRC calculation submodule
    crc8_calculator #(
        .POLY(8'h07)
    ) crc_calc_inst (
        .current_crc(crc),
        .data_in(data),
        .next_crc(next_crc)
    );
    
    // Instantiate register control submodule
    crc_register crc_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .next_crc(next_crc),
        .crc(crc)
    );
endmodule

// Submodule for CRC calculation logic
module crc8_calculator #(
    parameter POLY = 8'h07
)(
    input wire [7:0] current_crc,
    input wire [7:0] data_in,
    output wire [7:0] next_crc
);
    // Intermediate signals for each bit calculation
    wire [7:0] bit_crc [0:7];
    
    // Process each bit in sequence
    bit_processor #(.POLY(POLY)) bit0_proc (
        .current_crc(current_crc),
        .data_bit(data_in[0]),
        .next_crc(bit_crc[0])
    );
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : bit_proc_gen
            bit_processor #(.POLY(POLY)) bit_proc (
                .current_crc(bit_crc[i-1]),
                .data_bit(data_in[i]),
                .next_crc(bit_crc[i])
            );
        end
    endgenerate
    
    // Connect the output
    assign next_crc = bit_crc[7];
endmodule

// Submodule for single bit CRC processing
module bit_processor #(
    parameter POLY = 8'h07
)(
    input wire [7:0] current_crc,
    input wire data_bit,
    output wire [7:0] next_crc
);
    wire feedback;
    
    // Calculate feedback bit
    assign feedback = current_crc[7] ^ data_bit;
    
    // Calculate next CRC value
    assign next_crc = {current_crc[6:0], 1'b0} ^ (feedback ? POLY : 8'h00);
endmodule

// Submodule for register control
module crc_register(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [7:0] next_crc,
    output reg [7:0] crc
);
    // Register with synchronous reset and enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            crc <= 8'h00;
        else if (enable) 
            crc <= next_crc;
    end
endmodule