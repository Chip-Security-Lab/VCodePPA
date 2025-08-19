//SystemVerilog IEEE 1364-2005 Standard

// Top level module with AXI-Stream interface
module Matrix_AND(
    input  wire        aclk,
    input  wire        aresetn,
    // Input AXI-Stream interface
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,
    // Output AXI-Stream interface
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);
    // Internal signals
    wire [3:0] row, col;
    wire [7:0] matrix_res;
    reg  [7:0] pattern_constant;
    wire       input_data_valid;
    reg        output_data_valid;
    reg        output_data_last;
    
    // Input data extraction state machine
    localparam IDLE = 2'b00, PROCESS = 2'b01, WAIT_OUTPUT = 2'b10;
    reg [1:0] state;
    
    // Extract row and column data from input AXI-Stream
    assign {row, col} = s_axis_tdata;
    assign input_data_valid = s_axis_tvalid & s_axis_tready;
    assign s_axis_tready = (state == IDLE || state == PROCESS);
    
    // Connect to output AXI-Stream interface
    assign m_axis_tdata = matrix_res;
    assign m_axis_tvalid = output_data_valid;
    assign m_axis_tlast = output_data_last;
    
    // State machine for processing control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            pattern_constant <= 8'h55; // Default pattern
            output_data_valid <= 1'b0;
            output_data_last <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    output_data_valid <= 1'b0;
                    output_data_last <= 1'b0;
                    if (s_axis_tvalid) begin
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    if (input_data_valid) begin
                        output_data_valid <= 1'b1;
                        output_data_last <= s_axis_tlast;
                        state <= WAIT_OUTPUT;
                    end
                end
                
                WAIT_OUTPUT: begin
                    if (m_axis_tready) begin
                        output_data_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Instantiate submodules
    Input_Processing input_proc_inst (
        .row_in(row),
        .col_in(col),
        .processed_data_valid(input_data_valid),
        .processed_data(matrix_res[7:0])
    );
    
    // Pattern is now handled in the top-level state machine
    // Data processing is integrated into the Input_Processing module
endmodule

// Module for input processing with integrated data processing
module Input_Processing(
    input [3:0] row_in,
    input [3:0] col_in,
    input       processed_data_valid,
    output [7:0] processed_data
);
    // Internal signals
    wire [3:0] row_processed;
    wire [3:0] col_processed;
    wire [7:0] concatenated_data;
    wire [7:0] pattern_constant;
    
    // Optimized submodule instantiation
    assign row_processed = row_in;  // Simplified row processing
    assign col_processed = col_in;  // Simplified column processing
    
    // Concatenate processed row and column data
    assign concatenated_data = {row_processed, col_processed};
    
    // Fixed pattern generation
    assign pattern_constant = 8'h55; // 0101_0101 pattern
    
    // Integrated data processing (bitwise AND)
    assign processed_data = concatenated_data & pattern_constant;
endmodule