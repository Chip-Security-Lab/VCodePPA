module multi_shadow_reg #(
    parameter WIDTH = 8,
    parameter LEVELS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    input wire [1:0] shadow_select,
    output wire [WIDTH-1:0] shadow_out
);
    // Main register
    reg [WIDTH-1:0] main_reg;
    // Multiple shadow registers
    reg [WIDTH-1:0] shadow_reg [0:LEVELS-1];
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Shadow registers update
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < LEVELS; i = i + 1)
                shadow_reg[i] <= 0;
        end else if (capture) begin
            shadow_reg[0] <= main_reg;
            for (i = 1; i < LEVELS; i = i + 1)
                shadow_reg[i] <= shadow_reg[i-1];
        end
    end
    
    // Output selection
    assign shadow_out = shadow_reg[shadow_select];
endmodule