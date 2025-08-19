//SystemVerilog
module init_value_crc8(
    input wire clock,
    input wire resetn,
    input wire [7:0] init_value,
    input wire init_load,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] crc_out
);
    parameter [7:0] POLYNOMIAL = 8'hD5;
    
    // Optimized CRC calculation with parallel XOR operations
    wire [7:0] crc_shift = {crc_out[6:0], 1'b0};
    wire [7:0] poly_mask = {8{crc_out[7] ^ data[0]}} & POLYNOMIAL;
    wire [7:0] next_crc = crc_shift ^ poly_mask;
    
    // Control signals for case statement
    reg [1:0] ctrl_state;
    always @(*) begin
        if (!resetn)
            ctrl_state = 2'b00;
        else if (init_load)
            ctrl_state = 2'b01;
        else if (data_valid)
            ctrl_state = 2'b10;
        else
            ctrl_state = 2'b11;
    end
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            crc_out <= 8'h00;
        end
        else begin
            case (ctrl_state)
                2'b00: crc_out <= 8'h00;       // Reset state (redundant but kept for clarity)
                2'b01: crc_out <= init_value;  // Init load state
                2'b10: crc_out <= next_crc;    // Data valid state
                2'b11: crc_out <= crc_out;     // Hold current value
            endcase
        end
    end
endmodule