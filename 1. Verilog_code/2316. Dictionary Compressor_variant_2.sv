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
    
    // Registered input data and valid signal
    reg [SYMBOL_WIDTH-1:0] data_in_reg;
    reg valid_in_reg;
    
    // Match detection signals
    wire [DICT_SIZE-1:0] match_vector;
    wire match_found;
    wire [CODE_WIDTH-1:0] encoded_index;
    
    integer i;
    
    // Register input data
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= 0;
            valid_in_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            valid_in_reg <= valid_in;
        end
    end
    
    // Dictionary initialization
    always @(posedge clk) begin
        if (rst) begin
            // Initialize dictionary with common values
            for (i = 0; i < DICT_SIZE; i = i + 1)
                dictionary[i] <= i;
        end
    end
    
    // Generate match vector combinationally
    genvar g;
    generate
        for (g = 0; g < DICT_SIZE; g = g + 1) begin : gen_match
            assign match_vector[g] = (dictionary[g] == data_in_reg);
        end
    endgenerate
    
    // Match detection logic (combinational)
    assign match_found = |match_vector;
    
    // Priority encoder (combinational)
    function [CODE_WIDTH-1:0] priority_encode;
        input [DICT_SIZE-1:0] one_hot;
        integer j;
        begin
            priority_encode = 0;
            for (j = 0; j < DICT_SIZE; j = j + 1) begin
                if (one_hot[j]) 
                    priority_encode = j[CODE_WIDTH-1:0];
            end
        end
    endfunction
    
    assign encoded_index = priority_encode(match_vector);
    
    // Output register stage
    always @(posedge clk) begin
        if (rst) begin
            code_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_in_reg && match_found;
            if (valid_in_reg && match_found) begin
                code_out <= encoded_index;
            end
        end
    end
endmodule