module sync_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data
);
    // Primary register
    reg [WIDTH-1:0] primary_reg;
    
    // Primary register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            primary_reg <= {WIDTH{1'b0}};
        else
            primary_reg <= data_in;
    end
    
    // Shadow register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (capture)
            shadow_data <= primary_reg;
    end
endmodule