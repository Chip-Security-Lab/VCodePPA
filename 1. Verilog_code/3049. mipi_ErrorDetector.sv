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
    
    always @(posedge clk) begin
        if (rst) begin
            error_count <= 0;
            error_flags <= 0;
            timeout_counter <= 0;
        end else begin
            error_flags[0] <= crc_error;
            error_flags[1] <= timeout;
            error_flags[2] <= (data_valid && (data_in == 8'h00));
            
            if (|error_flags) begin
                error_count <= error_count + 1;
            end
            
            timeout_counter <= (data_valid) ? 0 : timeout_counter + 1;
            if (timeout_counter > 24'hFFFFFF) error_flags[1] <= 1;
        end
    end
endmodule
