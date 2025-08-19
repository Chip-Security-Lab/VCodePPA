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
    reg [3:0] match_index;
    reg match_found;
    reg [31:0] upper_word;
    reg [31:0] upper_word_pipe;
    reg [RAW_DW-1:0] raw_data_pipe;
    reg compress_en_pipe;
    reg [3:0] match_index_pipe;
    reg match_found_pipe;
    
    // Pipeline stage 1: Pre-compute and register inputs
    always @(posedge clk) begin
        upper_word_pipe <= raw_data[127:96];
        raw_data_pipe <= raw_data;
        compress_en_pipe <= compress_en;
    end
    
    // Pipeline stage 2: Parallel matching logic
    always @(*) begin
        match_found = 0;
        match_index = 4'h0;
        
        if (upper_word_pipe == dictionary[0][127:96]) begin
            match_found = 1;
            match_index = 4'h0;
        end else if (upper_word_pipe == dictionary[1][127:96]) begin
            match_found = 1;
            match_index = 4'h1;
        end else if (upper_word_pipe == dictionary[2][127:96]) begin
            match_found = 1;
            match_index = 4'h2;
        end else if (upper_word_pipe == dictionary[3][127:96]) begin
            match_found = 1;
            match_index = 4'h3;
        end else if (upper_word_pipe == dictionary[4][127:96]) begin
            match_found = 1;
            match_index = 4'h4;
        end else if (upper_word_pipe == dictionary[5][127:96]) begin
            match_found = 1;
            match_index = 4'h5;
        end else if (upper_word_pipe == dictionary[6][127:96]) begin
            match_found = 1;
            match_index = 4'h6;
        end else if (upper_word_pipe == dictionary[7][127:96]) begin
            match_found = 1;
            match_index = 4'h7;
        end else if (upper_word_pipe == dictionary[8][127:96]) begin
            match_found = 1;
            match_index = 4'h8;
        end else if (upper_word_pipe == dictionary[9][127:96]) begin
            match_found = 1;
            match_index = 4'h9;
        end else if (upper_word_pipe == dictionary[10][127:96]) begin
            match_found = 1;
            match_index = 4'hA;
        end else if (upper_word_pipe == dictionary[11][127:96]) begin
            match_found = 1;
            match_index = 4'hB;
        end else if (upper_word_pipe == dictionary[12][127:96]) begin
            match_found = 1;
            match_index = 4'hC;
        end else if (upper_word_pipe == dictionary[13][127:96]) begin
            match_found = 1;
            match_index = 4'hD;
        end else if (upper_word_pipe == dictionary[14][127:96]) begin
            match_found = 1;
            match_index = 4'hE;
        end else if (upper_word_pipe == dictionary[15][127:96]) begin
            match_found = 1;
            match_index = 4'hF;
        end
    end
    
    // Pipeline stage 3: Register match results
    always @(posedge clk) begin
        match_index_pipe <= match_index;
        match_found_pipe <= match_found;
    end
    
    // Pipeline stage 4: Main compression logic
    always @(posedge clk) begin
        if (compress_en_pipe) begin
            if (match_found_pipe) begin
                comp_data <= {4'hD, match_index_pipe, raw_data_pipe[95:0]};
                dict_updated <= 0;
            end else begin
                dictionary[dict_index] <= raw_data_pipe;
                comp_data <= {4'hF, dict_index, raw_data_pipe[95:0]};
                dict_index <= dict_index + 1;
                dict_updated <= 1;
            end
        end else begin
            dict_updated <= 0;
        end
    end
    
    // Reset logic
    always @(posedge clk) begin
        if (!compress_en_pipe && dict_index == 0) begin
            dictionary[0] <= {RAW_DW{1'b0}};
            dictionary[1] <= {RAW_DW{1'b0}};
            dictionary[2] <= {RAW_DW{1'b0}};
            dictionary[3] <= {RAW_DW{1'b0}};
            dictionary[4] <= {RAW_DW{1'b0}};
            dictionary[5] <= {RAW_DW{1'b0}};
            dictionary[6] <= {RAW_DW{1'b0}};
            dictionary[7] <= {RAW_DW{1'b0}};
            dictionary[8] <= {RAW_DW{1'b0}};
            dictionary[9] <= {RAW_DW{1'b0}};
            dictionary[10] <= {RAW_DW{1'b0}};
            dictionary[11] <= {RAW_DW{1'b0}};
            dictionary[12] <= {RAW_DW{1'b0}};
            dictionary[13] <= {RAW_DW{1'b0}};
            dictionary[14] <= {RAW_DW{1'b0}};
            dictionary[15] <= {RAW_DW{1'b0}};
        end
    end
endmodule