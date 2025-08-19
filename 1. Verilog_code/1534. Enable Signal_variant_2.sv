//SystemVerilog
// IEEE 1364-2005 Verilog标准
module enabled_shadow_reg #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_input,
    input wire shadow_capture,
    output reg [DATA_WIDTH-1:0] shadow_output
);
    // Main data register
    reg [DATA_WIDTH-1:0] data_reg;
    
    // Enable signal pipeline register to reduce fanout
    reg enable_pipe;
    
    // Shadow capture signal pipeline register
    reg shadow_capture_pipe;
    
    // Pipeline register for data input
    reg [DATA_WIDTH-1:0] data_input_pipe;
    
    // First stage: Pipeline input signals
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enable_pipe <= 1'b0;
            shadow_capture_pipe <= 1'b0;
            data_input_pipe <= {DATA_WIDTH{1'b0}};
        end
        else begin
            enable_pipe <= enable;
            shadow_capture_pipe <= shadow_capture;
            data_input_pipe <= data_input;
        end
    end
    
    // Second stage: Main register logic with enable
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            data_reg <= {DATA_WIDTH{1'b0}};
        else if (enable_pipe)
            data_reg <= data_input_pipe;
    end
    
    // Third stage: Shadow register capture logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            shadow_output <= {DATA_WIDTH{1'b0}};
        else if (shadow_capture_pipe && enable_pipe)
            shadow_output <= data_reg;
    end
endmodule