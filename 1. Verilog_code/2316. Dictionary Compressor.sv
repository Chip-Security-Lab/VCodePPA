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
    
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // Initialize dictionary with common values
            for (i = 0; i < DICT_SIZE; i = i + 1)
                dictionary[i] <= i;
            valid_out <= 0;
        end else if (valid_in) begin
            // Search dictionary
            valid_out <= 0;
            for (i = 0; i < DICT_SIZE; i = i + 1) begin
                if (dictionary[i] == data_in) begin
                    code_out <= i[CODE_WIDTH-1:0];
                    valid_out <= 1;
                end
            end
        end else begin
            valid_out <= 0;
        end
    end
endmodule