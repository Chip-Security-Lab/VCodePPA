//SystemVerilog
module MIPI_ErrorDetector #(
    parameter ERR_TYPE = 3
)(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire crc_error,
    input wire timeout,
    output reg [3:0] error_count,
    output reg [ERR_TYPE-1:0] error_flags
);

    // Pipeline stage 1 registers
    reg [7:0] data_in_stage1;
    reg data_valid_stage1;
    reg crc_error_stage1;
    reg timeout_stage1;
    reg [ERR_TYPE-1:0] error_flags_stage1;
    reg [23:0] timeout_counter_stage1;
    
    // Pipeline stage 2 registers
    reg [3:0] error_count_stage2;
    reg [ERR_TYPE-1:0] error_flags_stage2;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: Input sampling and error detection
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 0;
            data_in_stage1 <= 0;
            data_valid_stage1 <= 0;
            crc_error_stage1 <= 0;
            timeout_stage1 <= 0;
            error_flags_stage1 <= 0;
            timeout_counter_stage1 <= 0;
        end else begin
            valid_stage1 <= 1;
            data_in_stage1 <= data_in;
            data_valid_stage1 <= data_valid;
            crc_error_stage1 <= crc_error;
            timeout_stage1 <= timeout;
            
            error_flags_stage1[0] <= crc_error;
            error_flags_stage1[1] <= timeout;
            error_flags_stage1[2] <= (data_valid && (data_in == 8'h00));
            
            timeout_counter_stage1 <= (data_valid) ? 0 : timeout_counter_stage1 + 1;
            if (timeout_counter_stage1 > 24'hFFFFFF) 
                error_flags_stage1[1] <= 1;
        end
    end

    // Stage 2: Error counting and final output
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 0;
            error_count_stage2 <= 0;
            error_flags_stage2 <= 0;
        end else if (valid_stage1) begin
            valid_stage2 <= 1;
            error_flags_stage2 <= error_flags_stage1;
            
            if (|error_flags_stage1) begin
                error_count_stage2 <= error_count_stage2 + 1;
            end
        end else begin
            valid_stage2 <= 0;
        end
    end

    // Output assignment
    assign error_count = error_count_stage2;
    assign error_flags = error_flags_stage2;

endmodule