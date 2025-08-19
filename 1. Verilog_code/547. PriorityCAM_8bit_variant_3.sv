//SystemVerilog
module cam_7 (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire write_en,
    input wire write_high,
    input wire [7:0] data_in,
    output reg ready_out,
    output reg match,
    output reg [7:0] priority_data
);
    reg [7:0] high_priority, low_priority;
    reg data_valid;
    
    // Reset and ready_out control
    always @(posedge clk) begin
        if (rst) begin
            ready_out <= 1'b0;
        end else begin
            ready_out <= 1'b1;
        end
    end
    
    // High priority register update
    always @(posedge clk) begin
        if (rst) begin
            high_priority <= 8'b0;
        end else if (valid_in && ready_out && write_en && write_high) begin
            high_priority <= data_in;
        end
    end
    
    // Low priority register update
    always @(posedge clk) begin
        if (rst) begin
            low_priority <= 8'b0;
        end else if (valid_in && ready_out && write_en && !write_high) begin
            low_priority <= data_in;
        end
    end
    
    // Data valid control
    always @(posedge clk) begin
        if (rst) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= valid_in && ready_out;
        end
    end
    
    // Match detection for high priority
    always @(posedge clk) begin
        if (rst) begin
            match <= 1'b0;
        end else if (data_valid && high_priority == data_in) begin
            match <= 1'b1;
        end else if (data_valid && low_priority == data_in) begin
            match <= 1'b1;
        end else if (data_valid) begin
            match <= 1'b0;
        end
    end
    
    // Priority data selection
    always @(posedge clk) begin
        if (rst) begin
            priority_data <= 8'b0;
        end else if (data_valid && high_priority == data_in) begin
            priority_data <= high_priority;
        end else if (data_valid && low_priority == data_in) begin
            priority_data <= low_priority;
        end
    end
endmodule