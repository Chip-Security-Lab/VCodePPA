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
    output wire [3:0] error_count,
    output wire [ERR_TYPE-1:0] error_flags
);
    wire timeout_condition;
    wire zero_data_error;
    wire [ERR_TYPE-1:0] internal_error_flags;
    
    // Instantiate timeout detection submodule
    TimeoutDetector timeout_detector (
        .clk(clk),
        .rst(rst),
        .data_valid(data_valid),
        .timeout(timeout),
        .timeout_condition(timeout_condition)
    );
    
    // Instantiate error detection submodule
    ErrorDetector error_detector (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .crc_error(crc_error),
        .timeout_condition(timeout_condition),
        .zero_data_error(zero_data_error),
        .error_flags(internal_error_flags)
    );
    
    // Instantiate error counter submodule
    ErrorCounter error_counter (
        .clk(clk),
        .rst(rst),
        .error_flags(internal_error_flags),
        .error_count(error_count)
    );
    
    // Connect outputs
    assign error_flags = internal_error_flags;
endmodule

// Timeout detection submodule
module TimeoutDetector (
    input wire clk,
    input wire rst,
    input wire data_valid,
    input wire timeout,
    output wire timeout_condition
);
    reg [23:0] timeout_counter;
    
    assign timeout_condition = (timeout_counter > 24'hFFFFFF);
    
    always @(posedge clk) begin
        if (rst) begin
            timeout_counter <= 0;
        end else begin
            timeout_counter <= data_valid ? 24'd0 : timeout_counter + 24'd1;
        end
    end
endmodule

// Error detection submodule
module ErrorDetector (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire crc_error,
    input wire timeout_condition,
    output wire zero_data_error,
    output reg [2:0] error_flags
);
    assign zero_data_error = data_valid & ~(|data_in);
    
    always @(posedge clk) begin
        if (rst) begin
            error_flags <= 0;
        end else begin
            error_flags[0] <= crc_error;
            error_flags[1] <= timeout_condition;
            error_flags[2] <= zero_data_error;
        end
    end
endmodule

// Error counter submodule
module ErrorCounter (
    input wire clk,
    input wire rst,
    input wire [2:0] error_flags,
    output reg [3:0] error_count
);
    always @(posedge clk) begin
        if (rst) begin
            error_count <= 0;
        end else begin
            error_count <= error_count + (|error_flags);
        end
    end
endmodule