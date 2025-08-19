//SystemVerilog
module crc8_generator #(parameter DATA_W=8) (
    input clk, rst, en,
    input [DATA_W-1:0] data,
    output reg [7:0] crc
);

reg [7:0] crc_next;
reg [7:0] borrow;
reg [7:0] temp_result;

always @(*) begin
    // Initialize borrow and temp_result
    borrow = 8'b0;
    temp_result = 8'b0;
    
    // Shift CRC left by 1
    crc_next = {crc[6:0], 1'b0};
    
    // Borrow-based subtraction algorithm
    if (crc[7] ^ data[7]) begin
        // Need to subtract 8'h07
        // Start with the rightmost bit
        temp_result[0] = crc_next[0] ^ 1'b1; // 7 = 111 in binary
        borrow[0] = ~crc_next[0];
        
        // Process remaining bits with borrow propagation
        for (integer i = 1; i < 8; i = i + 1) begin
            if (i < 3) begin // For bits 1 and 2, we need to subtract 1
                temp_result[i] = crc_next[i] ^ 1'b1 ^ borrow[i-1];
                borrow[i] = (~crc_next[i] & 1'b1) | (~crc_next[i] & borrow[i-1]) | (1'b1 & borrow[i-1]);
            end else begin // For bits 3-7, no subtraction needed
                temp_result[i] = crc_next[i] ^ borrow[i-1];
                borrow[i] = ~crc_next[i] & borrow[i-1];
            end
        end
    end else begin
        temp_result = crc_next;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) 
        crc <= 8'hFF;
    else if (en) 
        crc <= temp_result;
end

endmodule