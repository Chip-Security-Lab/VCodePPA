//SystemVerilog
module elias_gamma (
    input            valid,   // Valid signal (was 'req')
    input     [15:0] value,   // Input value to encode
    output reg [31:0] code,   // Encoded output
    output reg [5:0]  length, // Length of encoded output
    input            ready    // Ready signal (was 'ack')
);
    reg [4:0] msb_pos;
    reg [31:0] encoded_value;
    
    always @(*) begin
        if (valid) begin
            // Find MSB position using cascaded comparisons for better timing
            if (value[15])      msb_pos = 5'd15;
            else if (value[14]) msb_pos = 5'd14;
            else if (value[13]) msb_pos = 5'd13;
            else if (value[12]) msb_pos = 5'd12;
            else if (value[11]) msb_pos = 5'd11;
            else if (value[10]) msb_pos = 5'd10;
            else if (value[9])  msb_pos = 5'd9;
            else if (value[8])  msb_pos = 5'd8;
            else if (value[7])  msb_pos = 5'd7;
            else if (value[6])  msb_pos = 5'd6;
            else if (value[5])  msb_pos = 5'd5;
            else if (value[4])  msb_pos = 5'd4;
            else if (value[3])  msb_pos = 5'd3;
            else if (value[2])  msb_pos = 5'd2;
            else if (value[1])  msb_pos = 5'd1;
            else                msb_pos = 5'd0;
            
            // Calculate length
            length = {1'b0, msb_pos} + msb_pos + 5'd1;
            
            // Generate code using bit operations instead of loops
            // First part: msb_pos zeros followed by a 1
            encoded_value = (32'b1 << (31 - msb_pos));
            
            // Second part: append msb_pos bits from value
            if (msb_pos > 0) begin
                encoded_value = encoded_value | 
                               ((value & ((1 << msb_pos) - 1)) << (31 - 2*msb_pos));
            end
            
            code = encoded_value;
        end
        else begin
            code = 32'b0;
            length = 6'b0;
            msb_pos = 5'b0;
        end
    end
endmodule