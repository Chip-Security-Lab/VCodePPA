module async_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shadow_en,
    output wire [WIDTH-1:0] shadow_out
);
    reg [WIDTH-1:0] main_reg;
    reg [WIDTH-1:0] shadow_reg;
    
    // Main register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Asynchronous shadow capture using combinational logic
    assign shadow_out = shadow_en ? main_reg : shadow_reg;
    
    // Store shadow value when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_reg <= 0;
        else if (shadow_en)
            shadow_reg <= main_reg;
    end
endmodule