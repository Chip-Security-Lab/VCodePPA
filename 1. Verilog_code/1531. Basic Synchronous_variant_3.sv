//SystemVerilog
// IEEE 1364-2005 Standard
module sync_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data
);
    // Data register after moving forward through combinational logic
    reg [WIDTH-1:0] data_reg;
    
    // Register for capture signal
    reg capture_reg;
    
    // Two-stage always blocks to separate the input registers from output logic
    
    // Input register stage - moved forward
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {WIDTH{1'b0}};
            capture_reg <= 1'b0;
        end
        else begin
            data_reg <= data_in;
            capture_reg <= capture;
        end
    end
    
    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
        end
        else if (capture_reg) begin
            shadow_data <= data_reg;
        end
    end
endmodule