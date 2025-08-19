//SystemVerilog
// IEEE 1364-2005 Verilog
module auto_snapshot_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire error_detected,
    output reg [WIDTH-1:0] shadow_data,
    output reg snapshot_taken
);
    // Register data_in to reduce input to register delay
    reg [WIDTH-1:0] data_in_reg;
    
    // Error detection signal
    reg error_detected_reg;
    reg error_detected_rise;
    
    // Register input data to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_reg <= 0;
        else
            data_in_reg <= data_in;
    end
    
    // Register the error detection signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_detected_reg <= 0;
            error_detected_rise <= 0;
        end else begin
            error_detected_reg <= error_detected;
            error_detected_rise <= error_detected && !error_detected_reg;
        end
    end
    
    // Automatic shadow capture based on registered error signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            snapshot_taken <= 0;
        end else if (error_detected_rise && !snapshot_taken) begin
            shadow_data <= data_in_reg; // Use registered data
            snapshot_taken <= 1;
        end else if (!error_detected_reg) begin
            snapshot_taken <= 0;
        end
    end
endmodule