//SystemVerilog
module parallel_crc32(
    input wire clock,
    input wire clear,
    input wire [31:0] data_word,
    input wire word_valid,
    output reg [31:0] crc_value
);
    localparam POLY = 32'h04C11DB7;
    
    reg [31:0] crc_table [0:7];
    wire [31:0] next_crc;
    
    initial begin
        crc_table[0] = POLY;
        crc_table[1] = POLY >> 1;
        crc_table[2] = POLY >> 2;
        crc_table[3] = POLY >> 3;
        crc_table[4] = POLY >> 4;
        crc_table[5] = POLY >> 5;
        crc_table[6] = POLY >> 6;
        crc_table[7] = POLY >> 7;
    end
    
    wire [31:0] byte_masks[0:3];
    
    assign byte_masks[0] = {
        {8{data_word[31]}}, {8{data_word[30]}}, {8{data_word[29]}}, {8{data_word[28]}},
        {8{data_word[27]}}, {8{data_word[26]}}, {8{data_word[25]}}, {8{data_word[24]}}
    };
    
    assign byte_masks[1] = {
        {8{data_word[23]}}, {8{data_word[22]}}, {8{data_word[21]}}, {8{data_word[20]}},
        {8{data_word[19]}}, {8{data_word[18]}}, {8{data_word[17]}}, {8{data_word[16]}}
    };
    
    assign byte_masks[2] = {
        {8{data_word[15]}}, {8{data_word[14]}}, {8{data_word[13]}}, {8{data_word[12]}},
        {8{data_word[11]}}, {8{data_word[10]}}, {8{data_word[9]}}, {8{data_word[8]}}
    };
    
    assign byte_masks[3] = {
        {8{data_word[7]}}, {8{data_word[6]}}, {8{data_word[5]}}, {8{data_word[4]}},
        {8{data_word[3]}}, {8{data_word[2]}}, {8{data_word[1]}}, {8{data_word[0]}}
    };
    
    wire [31:0] byte_results[0:3];
    
    function [31:0] process_byte(input [31:0] prev_result, input integer byte_idx);
        reg [31:0] result;
        reg [31:0] mask;
        begin
            result = prev_result << 8;
            mask = byte_masks[byte_idx];
            
            // 展开的循环处理
            if (mask[0]) result = result ^ crc_table[0];
            if (mask[4]) result = result ^ crc_table[1];
            if (mask[8]) result = result ^ crc_table[2];
            if (mask[12]) result = result ^ crc_table[3];
            if (mask[16]) result = result ^ crc_table[4];
            if (mask[20]) result = result ^ crc_table[5];
            if (mask[24]) result = result ^ crc_table[6];
            if (mask[28]) result = result ^ crc_table[7];
            
            process_byte = result;
        end
    endfunction
    
    assign byte_results[0] = process_byte(crc_value, 0);
    assign byte_results[1] = process_byte(byte_results[0], 1);
    assign byte_results[2] = process_byte(byte_results[1], 2);
    assign byte_results[3] = process_byte(byte_results[2], 3);
    
    assign next_crc = byte_results[3];
    
    always @(posedge clock) begin
        if (clear) 
            crc_value <= 32'hFFFFFFFF;
        else if (word_valid) 
            crc_value <= next_crc;
    end
endmodule