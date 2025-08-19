module priority_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_high_pri,
    input wire high_pri_valid,
    input wire [WIDTH-1:0] data_low_pri,
    input wire low_pri_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // Priority-based input selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 0;
        else if (high_pri_valid)
            data_reg <= data_high_pri;
        else if (low_pri_valid)
            data_reg <= data_low_pri;
    end
    
    // Shadow update on any valid data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= 0;
        else if (high_pri_valid || low_pri_valid)
            shadow_out <= data_reg;
    end
endmodule