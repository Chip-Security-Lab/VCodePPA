//SystemVerilog
module dictionary_compressor #(
    parameter DICT_SIZE = 16,
    parameter SYMBOL_WIDTH = 8,
    parameter CODE_WIDTH = 4
)(
    input                       clk,
    input                       rst,
    input  [SYMBOL_WIDTH-1:0]   data_in,
    input                       valid_in,
    output reg [CODE_WIDTH-1:0] code_out,
    output reg                  valid_out
);
    // Dictionary storage
    reg [SYMBOL_WIDTH-1:0] dictionary [0:DICT_SIZE-1];
    
    // Use multiple buffered index signals to reduce fan-out
    reg [$clog2(DICT_SIZE)-1:0] index_init;
    reg [$clog2(DICT_SIZE)-1:0] index_search_group1 [0:DICT_SIZE/4-1];
    reg [$clog2(DICT_SIZE)-1:0] index_search_group2 [0:DICT_SIZE/4-1];
    reg [$clog2(DICT_SIZE)-1:0] index_search_group3 [0:DICT_SIZE/4-1];
    reg [$clog2(DICT_SIZE)-1:0] index_search_group4 [0:DICT_SIZE/4-1];
    
    // Match signals for each group
    reg [DICT_SIZE/4-1:0] match_group1;
    reg [DICT_SIZE/4-1:0] match_group2;
    reg [DICT_SIZE/4-1:0] match_group3;
    reg [DICT_SIZE/4-1:0] match_group4;
    
    // Pipeline registers for improved timing
    reg valid_in_r;
    reg [SYMBOL_WIDTH-1:0] data_in_r;
    
    // Group match indicators for case statement
    reg [3:0] group_match;
    reg [$clog2(DICT_SIZE/4)-1:0] match_index;
    
    integer i;
    
    // Initialize indices in a separate always block to distribute fan-out
    always @(posedge clk) begin
        if (rst) begin
            index_init <= 0;
        end else if (index_init < DICT_SIZE-1) begin
            index_init <= index_init + 1;
        end
    end
    
    // Initialize dictionary and buffer indices for multiple groups
    always @(posedge clk) begin
        if (rst) begin
            // Initialize dictionary with common values
            dictionary[index_init] <= index_init[$clog2(DICT_SIZE)-1:0];
            
            // Reset match signals
            for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
                index_search_group1[i] <= i;
                index_search_group2[i] <= i + DICT_SIZE/4;
                index_search_group3[i] <= i + DICT_SIZE/2;
                index_search_group4[i] <= i + 3*DICT_SIZE/4;
                
                match_group1[i] <= 0;
                match_group2[i] <= 0;
                match_group3[i] <= 0;
                match_group4[i] <= 0;
            end
            
            valid_out <= 0;
            valid_in_r <= 0;
        end else begin
            valid_in_r <= valid_in;
            data_in_r <= data_in;
            
            // Process match detection in parallel groups to reduce fan-out
            case (valid_in_r)
                1'b1: begin
                    for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
                        match_group1[i] <= (dictionary[index_search_group1[i]] == data_in_r) ? 1'b1 : 1'b0;
                        match_group2[i] <= (dictionary[index_search_group2[i]] == data_in_r) ? 1'b1 : 1'b0;
                        match_group3[i] <= (dictionary[index_search_group3[i]] == data_in_r) ? 1'b1 : 1'b0;
                        match_group4[i] <= (dictionary[index_search_group4[i]] == data_in_r) ? 1'b1 : 1'b0;
                    end
                end
                
                default: begin  // 1'b0 or x/z
                    for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
                        match_group1[i] <= 0;
                        match_group2[i] <= 0;
                        match_group3[i] <= 0;
                        match_group4[i] <= 0;
                    end
                end
            endcase
        end
    end
    
    // Determine which group has a match and the index within that group
    always @(*) begin
        group_match = 4'b0000;
        match_index = 0;
        
        for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
            if (match_group1[i]) begin
                group_match = 4'b0001;
                match_index = i[$clog2(DICT_SIZE/4)-1:0];
            end
        end
        
        for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
            if (match_group2[i]) begin
                group_match = 4'b0010;
                match_index = i[$clog2(DICT_SIZE/4)-1:0];
            end
        end
        
        for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
            if (match_group3[i]) begin
                group_match = 4'b0100;
                match_index = i[$clog2(DICT_SIZE/4)-1:0];
            end
        end
        
        for (i = 0; i < DICT_SIZE/4; i = i + 1) begin
            if (match_group4[i]) begin
                group_match = 4'b1000;
                match_index = i[$clog2(DICT_SIZE/4)-1:0];
            end
        end
    end
    
    // Output generation with reduced critical path using case statement
    always @(posedge clk) begin
        if (rst) begin
            code_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= 0;
            
            case (group_match)
                4'b0001: begin  // Group 1 match
                    code_out <= index_search_group1[match_index][CODE_WIDTH-1:0];
                    valid_out <= 1;
                end
                
                4'b0010: begin  // Group 2 match
                    code_out <= index_search_group2[match_index][CODE_WIDTH-1:0];
                    valid_out <= 1;
                end
                
                4'b0100: begin  // Group 3 match
                    code_out <= index_search_group3[match_index][CODE_WIDTH-1:0];
                    valid_out <= 1;
                end
                
                4'b1000: begin  // Group 4 match
                    code_out <= index_search_group4[match_index][CODE_WIDTH-1:0];
                    valid_out <= 1;
                end
                
                default: begin  // No match
                    code_out <= 0;
                    valid_out <= 0;
                end
            endcase
        end
    end
endmodule