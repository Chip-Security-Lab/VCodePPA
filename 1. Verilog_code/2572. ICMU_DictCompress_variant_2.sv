//SystemVerilog
module ICMU_DictCompress #(
    parameter RAW_DW = 128,
    parameter COMP_DW = 64
)(
    input clk,
    input compress_en,
    input [RAW_DW-1:0] raw_data,
    output reg [COMP_DW-1:0] comp_data,
    output reg dict_updated
);

    // Dictionary storage and index
    reg [RAW_DW-1:0] dictionary [0:15];
    reg [3:0] dict_index;
    
    // Match detection signals
    reg [31:0] best_match;
    reg match_found;
    
    // Manchester carry chain signals
    wire [95:0] sum;
    wire [95:0] carry;
    wire [95:0] prop;
    wire [95:0] gen;
    
    // Manchester carry chain implementation
    genvar j;
    generate
        for (j = 0; j < 96; j = j + 1) begin : manchester_chain
            if (j == 0) begin
                assign prop[j] = raw_data[j] ^ dictionary[dict_index][j];
                assign gen[j] = raw_data[j] & dictionary[dict_index][j];
                assign carry[j] = gen[j];
                assign sum[j] = prop[j];
            end else begin
                assign prop[j] = raw_data[j] ^ dictionary[dict_index][j];
                assign gen[j] = raw_data[j] & dictionary[dict_index][j];
                assign carry[j] = gen[j] | (prop[j] & carry[j-1]);
                assign sum[j] = prop[j] ^ carry[j-1];
            end
        end
    endgenerate

    // Dictionary match search logic
    always @(posedge clk) begin
        if (compress_en) begin
            best_match <= 32'hFFFFFFFF;
            match_found <= 0;
            
            for (integer i = 0; i < 16; i=i+1) begin
                if (raw_data[127:96] == dictionary[i][127:96] && !match_found) begin
                    best_match <= i;
                    match_found <= 1;
                end
            end
        end
    end

    // Compression and dictionary update logic
    always @(posedge clk) begin
        if (compress_en) begin
            if (best_match != 32'hFFFFFFFF) begin
                comp_data <= {4'hD, best_match[3:0], sum};
                dict_updated <= 0;
            end else begin
                dictionary[dict_index] <= raw_data;
                comp_data <= {4'hF, dict_index, sum};
                dict_index <= dict_index + 1;
                dict_updated <= 1;
            end
        end else begin
            dict_updated <= 0;
        end
    end
    
    // Dictionary initialization logic
    always @(posedge clk) begin
        if (!compress_en && dict_index == 0) begin
            for (integer i = 0; i < 16; i=i+1) begin
                dictionary[i] <= {RAW_DW{1'b0}};
            end
        end
    end
endmodule