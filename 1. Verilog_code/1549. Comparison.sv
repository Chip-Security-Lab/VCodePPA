module compare_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update_main,
    input wire update_shadow,
    output reg [WIDTH-1:0] main_data,
    output reg [WIDTH-1:0] shadow_data,
    output reg data_match
);
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_data <= 0;
        else if (update_main)
            main_data <= data_in;
    end
    
    // Shadow register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= 0;
        else if (update_shadow)
            shadow_data <= data_in;
    end
    
    // Continuous comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_match <= 0;
        else
            data_match <= (main_data == shadow_data);
    end
endmodule