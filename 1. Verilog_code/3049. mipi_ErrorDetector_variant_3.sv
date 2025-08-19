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

    reg [23:0] timeout_counter;
    reg timeout_detected;
    reg data_empty;
    reg any_error;
    
    // Reset logic
    always @(posedge clk) begin
        if (rst) begin
            error_count <= 0;
            error_flags <= 0;
            timeout_counter <= 0;
            timeout_detected <= 0;
            data_empty <= 0;
            any_error <= 0;
        end
    end
    
    // Timeout detection logic
    always @(posedge clk) begin
        if (!rst) begin
            // Check if timeout counter has reached threshold
            if (timeout_counter[23] && timeout_counter[22] && timeout_counter[21]) begin
                timeout_detected <= 1'b1;
            end else begin
                timeout_detected <= 1'b0;
            end
        end
    end
    
    // Data empty detection
    always @(posedge clk) begin
        if (!rst) begin
            if (data_valid) begin
                data_empty <= (data_in == 8'h00);
            end
        end
    end
    
    // Error flag generation
    always @(posedge clk) begin
        if (!rst) begin
            // CRC error flag
            error_flags[0] <= crc_error;
            
            // Timeout error flag
            error_flags[1] <= timeout || timeout_detected;
            
            // Data empty error flag
            error_flags[2] <= data_valid && data_empty;
        end
    end
    
    // Error detection
    always @(posedge clk) begin
        if (!rst) begin
            any_error <= |error_flags;
        end
    end
    
    // Error counter
    always @(posedge clk) begin
        if (!rst && any_error) begin
            error_count <= error_count + 1'b1;
        end
    end
    
    // Timeout counter
    always @(posedge clk) begin
        if (!rst) begin
            if (data_valid) begin
                timeout_counter <= 24'd0;
            end else begin
                timeout_counter <= timeout_counter + 1'b1;
            end
        end
    end

endmodule