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
    reg [15:0] match_vector;
    reg [3:0] match_index;
    reg match_found;

    // LUT for match detection
    always @(*) begin
        match_vector = 16'h0;
        for (int i = 0; i < 16; i++) begin
            match_vector[i] = (raw_data[127:96] == dictionary[i][127:96]);
        end
    end

    // Priority encoder for match index
    always @(*) begin
        match_index = 4'd0;
        match_found = 1'b0;
        for (int i = 0; i < 16; i++) begin
            if (match_vector[i] && !match_found) begin
                match_index = i[3:0];
                match_found = 1'b1;
            end
        end
    end

    // Main compression logic
    always @(posedge clk) begin
        if (compress_en) begin
            if (match_found) begin
                comp_data <= {4'hD, match_index, raw_data[95:0]};
                dict_updated <= 0;
            end else begin
                dictionary[dict_index] <= raw_data;
                comp_data <= {4'hF, dict_index, raw_data[95:0]};
                dict_index <= dict_index + 1;
                dict_updated <= 1;
            end
        end else begin
            dict_updated <= 0;
        end
    end

    // Dictionary initialization
    always @(posedge clk) begin
        if (!compress_en && dict_index == 0) begin
            for (int i = 0; i < 16; i++) begin
                dictionary[i] <= {RAW_DW{1'b0}};
            end
        end
    end
endmodule