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

    reg [RAW_DW-1:0] dictionary [0:15];
    reg [3:0] dict_index;
    reg [31:0] best_match;
    reg match_found;
    integer i;

    always @(posedge clk) begin
        if (compress_en) begin
            best_match <= 32'hFFFFFFFF;
            match_found <= 0;
            
            for (i = 0; i < 16; i=i+1) begin
                if (raw_data[127:96] == dictionary[i][127:96] && !match_found) begin
                    best_match <= i;
                    match_found <= 1;
                end
            end

            if (best_match != 32'hFFFFFFFF) begin
                comp_data <= {4'hD, best_match[3:0], raw_data[95:0]};
                dict_updated <= 0;
            end else begin
                dictionary[dict_index] <= raw_data;
                comp_data <= {4'hF, dict_index, raw_data[95:0]};
                dict_index <= dict_index + 1;
                dict_updated <= 1;
            end
        end else begin
            dict_updated <= 0;
            if (dict_index == 0) begin
                for (i = 0; i < 16; i=i+1) begin
                    dictionary[i] <= {RAW_DW{1'b0}};
                end
            end
        end
    end

endmodule