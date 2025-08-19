//SystemVerilog
module tunstall_encoder #(
    parameter CODEWORD_WIDTH = 4
)(
    input                           clk_i,
    input                           enable_i,
    input                           rst_i,
    input      [7:0]                data_i,
    input                           data_valid_i,
    output     [CODEWORD_WIDTH-1:0] code_o,
    output                          code_valid_o
);
    // Internal signals
    wire [7:0] buffer;
    wire       buffer_valid;
    wire       process_data;
    wire [3:0] mapping_index;
    wire [CODEWORD_WIDTH-1:0] code_next;
    wire       code_valid_next;

    // Instantiate combinational logic module
    tunstall_comb_logic #(
        .CODEWORD_WIDTH(CODEWORD_WIDTH)
    ) comb_logic_inst (
        .enable_i(enable_i),
        .data_i(data_i),
        .data_valid_i(data_valid_i),
        .buffer_i(buffer),
        .buffer_valid_i(buffer_valid),
        .process_data_o(process_data),
        .mapping_index_o(mapping_index),
        .code_next_o(code_next),
        .code_valid_next_o(code_valid_next)
    );

    // Instantiate sequential logic module
    tunstall_seq_logic #(
        .CODEWORD_WIDTH(CODEWORD_WIDTH)
    ) seq_logic_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .enable_i(enable_i),
        .data_i(data_i),
        .data_valid_i(data_valid_i),
        .process_data_i(process_data),
        .mapping_index_i(mapping_index),
        .code_next_i(code_next),
        .code_valid_next_i(code_valid_next),
        .buffer_o(buffer),
        .buffer_valid_o(buffer_valid),
        .code_o(code_o),
        .code_valid_o(code_valid_o)
    );

endmodule

// Combinational logic module
module tunstall_comb_logic #(
    parameter CODEWORD_WIDTH = 4
)(
    input                           enable_i,
    input      [7:0]                data_i,
    input                           data_valid_i,
    input      [7:0]                buffer_i,
    input                           buffer_valid_i,
    output                          process_data_o,
    output     [3:0]                mapping_index_o,
    output     [CODEWORD_WIDTH-1:0] code_next_o,
    output                          code_valid_next_o
);
    // Combinational logic for process_data
    assign process_data_o = enable_i && data_valid_i && buffer_valid_i;
    
    // Combinational logic for mapping index calculation
    assign mapping_index_o = {buffer_i[1:0], data_i[1:0]};
    
    // Combinational logic for code output
    assign code_next_o = mapping_index_o;
    
    // Combinational logic for code valid signal
    assign code_valid_next_o = process_data_o;

endmodule

// Sequential logic module
module tunstall_seq_logic #(
    parameter CODEWORD_WIDTH = 4
)(
    input                           clk_i,
    input                           rst_i,
    input                           enable_i,
    input      [7:0]                data_i,
    input                           data_valid_i,
    input                           process_data_i,
    input      [3:0]                mapping_index_i,
    input      [CODEWORD_WIDTH-1:0] code_next_i,
    input                           code_valid_next_i,
    output reg [7:0]                buffer_o,
    output reg                      buffer_valid_o,
    output reg [CODEWORD_WIDTH-1:0] code_o,
    output reg                      code_valid_o
);
    // Sequential logic for buffer management
    always @(posedge clk_i) begin
        if (rst_i) begin
            buffer_o <= 8'h0;
            buffer_valid_o <= 1'b0;
        end else if (enable_i) begin
            if (data_valid_i) begin
                if (buffer_valid_o) begin
                    // Process and clear in same cycle when both valid
                    buffer_o <= 8'h0;
                    buffer_valid_o <= 1'b0;
                end else begin
                    // Store new data
                    buffer_o <= data_i;
                    buffer_valid_o <= 1'b1;
                end
            end
        end
    end
    
    // Sequential logic for code output
    always @(posedge clk_i) begin
        if (rst_i) begin
            code_o <= {CODEWORD_WIDTH{1'b0}};
        end else if (process_data_i) begin
            code_o <= code_next_i;
        end
    end
    
    // Sequential logic for code valid signal
    always @(posedge clk_i) begin
        if (rst_i || !enable_i) begin
            code_valid_o <= 1'b0;
        end else begin
            code_valid_o <= code_valid_next_i;
        end
    end

endmodule