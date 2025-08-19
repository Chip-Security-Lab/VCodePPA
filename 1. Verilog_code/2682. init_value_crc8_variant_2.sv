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
    
    // Feedback calculation logic
    wire feedback;
    wire [7:0] next_crc;
    
    // CRC feedback computation
    assign feedback = crc_out[7] ^ data[0];
    
    // Next CRC value calculation based on polynomial
    assign next_crc = {crc_out[6:0], 1'b0} ^ (feedback ? POLYNOMIAL : 8'h00);
    
    // Reset logic handling
    always @(negedge resetn) begin
        if (!resetn) 
            crc_out <= 8'h00;
    end
    
    // CRC update logic
    always @(posedge clock) begin
        if (resetn) begin
            // Initialization value loading has higher priority
            if (init_load) 
                crc_out <= init_value;
            // Process new data when valid
            else if (data_valid) 
                crc_out <= next_crc;
        end
    end
endmodule