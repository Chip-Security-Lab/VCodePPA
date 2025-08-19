//SystemVerilog
//------------------------------------------------------
// Top-level module: dictionary_compressor
//------------------------------------------------------
module dictionary_compressor #(
    parameter DICT_SIZE = 16,
    parameter SYMBOL_WIDTH = 8,
    parameter CODE_WIDTH = 4
)(
    input                       clk,
    input                       rst,
    input  [SYMBOL_WIDTH-1:0]   data_in,
    input                       valid_in,
    output [CODE_WIDTH-1:0]     code_out,
    output                      valid_out
);
    // Internal signals - registered inputs for timing improvement
    reg [SYMBOL_WIDTH-1:0]     data_in_reg;
    reg                        valid_in_reg;
    wire [CODE_WIDTH-1:0]      match_code;
    wire                       match_found;
    wire [SYMBOL_WIDTH-1:0]    dict_entries [0:DICT_SIZE-1];
    
    // Register input signals to improve input timing path
    always @(posedge clk) begin
        data_in_reg <= data_in;
        valid_in_reg <= valid_in;
    end
    
    // Dictionary storage submodule
    dictionary_storage #(
        .DICT_SIZE(DICT_SIZE),
        .SYMBOL_WIDTH(SYMBOL_WIDTH)
    ) dict_storage_inst (
        .clk(clk),
        .rst(rst),
        .dict_entries(dict_entries)
    );
    
    // Dictionary lookup submodule with retimed inputs
    dictionary_lookup #(
        .DICT_SIZE(DICT_SIZE),
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .CODE_WIDTH(CODE_WIDTH)
    ) dict_lookup_inst (
        .clk(clk),
        .valid_in(valid_in_reg),
        .data_in(data_in_reg),
        .dict_entries(dict_entries),
        .match_code(match_code),
        .match_found(match_found)
    );
    
    // Output controller submodule
    output_controller #(
        .CODE_WIDTH(CODE_WIDTH)
    ) output_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .match_code(match_code),
        .match_found(match_found),
        .code_out(code_out),
        .valid_out(valid_out)
    );
    
endmodule

//------------------------------------------------------
// Dictionary storage submodule
//------------------------------------------------------
module dictionary_storage #(
    parameter DICT_SIZE = 16,
    parameter SYMBOL_WIDTH = 8
)(
    input                           clk,
    input                           rst,
    output reg [SYMBOL_WIDTH-1:0]   dict_entries [0:DICT_SIZE-1]
);
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            // Initialize dictionary with common values
            for (i = 0; i < DICT_SIZE; i = i + 1)
                dict_entries[i] <= i[SYMBOL_WIDTH-1:0];
        end
    end
endmodule

//------------------------------------------------------
// Dictionary lookup submodule
//------------------------------------------------------
module dictionary_lookup #(
    parameter DICT_SIZE = 16,
    parameter SYMBOL_WIDTH = 8,
    parameter CODE_WIDTH = 4
)(
    input                           clk,
    input                           valid_in,
    input      [SYMBOL_WIDTH-1:0]   data_in,
    input      [SYMBOL_WIDTH-1:0]   dict_entries [0:DICT_SIZE-1],
    output reg [CODE_WIDTH-1:0]     match_code,
    output reg                      match_found
);
    // Internal signals for combinational logic
    reg [DICT_SIZE-1:0] match_vector;
    reg [CODE_WIDTH-1:0] encoder_output;
    reg found_flag;
    
    // Combinational logic for dictionary comparison
    integer i;
    always @(*) begin
        match_vector = {DICT_SIZE{1'b0}};
        found_flag = 1'b0;
        encoder_output = {CODE_WIDTH{1'b0}};
        
        if (valid_in) begin
            for (i = 0; i < DICT_SIZE; i = i + 1) begin
                if (dict_entries[i] == data_in) begin
                    match_vector[i] = 1'b1;
                    found_flag = 1'b1;
                    encoder_output = i[CODE_WIDTH-1:0];
                end
            end
        end
    end
    
    // Register the outputs of the combinational logic
    always @(posedge clk) begin
        match_found <= found_flag;
        match_code <= encoder_output;
    end
endmodule

//------------------------------------------------------
// Output controller submodule
//------------------------------------------------------
module output_controller #(
    parameter CODE_WIDTH = 4
)(
    input                       clk,
    input                       rst,
    input  [CODE_WIDTH-1:0]     match_code,
    input                       match_found,
    output reg [CODE_WIDTH-1:0] code_out,
    output reg                  valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            code_out <= {CODE_WIDTH{1'b0}};
        end else begin
            valid_out <= match_found;
            if (match_found) begin
                code_out <= match_code;
            end
        end
    end
endmodule