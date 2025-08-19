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
    // Main data register
    reg [WIDTH-1:0] main_reg;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else 
            main_reg <= data_in;
    end
    
    // Automatic shadow capture on error detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            snapshot_taken <= 0;
        end else if (error_detected && !snapshot_taken) begin
            shadow_data <= main_reg;
            snapshot_taken <= 1;
        end else if (!error_detected) begin
            snapshot_taken <= 0;
        end
    end
endmodule