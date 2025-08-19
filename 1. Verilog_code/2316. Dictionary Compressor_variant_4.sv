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
    
    // Search results for each dictionary entry
    reg [DICT_SIZE-1:0] match_stage1;
    
    // Pipeline registers for data
    reg [SYMBOL_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline control signals
    reg found_stage1;
    reg [CODE_WIDTH-1:0] code_stage1;
    
    integer i;
    
    // Stage 1: Dictionary lookup and match detection
    always @(posedge clk) begin
        if (rst) begin
            // Initialize dictionary with common values
            for (i = 0; i < DICT_SIZE; i = i + 1)
                dictionary[i] <= i;
                
            // Reset pipeline registers
            data_stage1 <= 0;
            valid_stage1 <= 0;
            for (i = 0; i < DICT_SIZE; i = i + 1)
                match_stage1[i] <= 0;
            found_stage1 <= 0;
            code_stage1 <= 0;
        end else begin
            // Register input data and valid signal
            data_stage1 <= data_in;
            valid_stage1 <= valid_in;
            
            // Perform parallel dictionary lookup
            if (valid_in) begin
                for (i = 0; i < DICT_SIZE; i = i + 1)
                    match_stage1[i] <= (dictionary[i] == data_in);
            end else begin
                for (i = 0; i < DICT_SIZE; i = i + 1)
                    match_stage1[i] <= 0;
            end
        end
    end
    
    // Stage 1: Priority encoder (combinational)
    always @(*) begin
        found_stage1 = 0;
        code_stage1 = 0;
        
        for (i = 0; i < DICT_SIZE; i = i + 1) begin
            if (match_stage1[i] && !found_stage1) begin
                code_stage1 = i[CODE_WIDTH-1:0];
                found_stage1 = 1;
            end
        end
    end
    
    // Stage 2: Output generation
    always @(posedge clk) begin
        if (rst) begin
            code_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage1 && found_stage1;
            if (valid_stage1 && found_stage1) begin
                code_out <= code_stage1;
            end
        end
    end
endmodule