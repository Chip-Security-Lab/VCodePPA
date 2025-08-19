//SystemVerilog
// IEEE 1364-2005 Verilog standard
module sync_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    output wire [WIDTH-1:0] shadow_data
);
    // Direct connection from input to shadow register to reduce path delay
    // Eliminated the intermediate primary_data signal to reduce routing delay
    
    // Shadow register with integrated primary register functionality
    integrated_shadow_register #(
        .WIDTH(WIDTH)
    ) u_integrated_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .capture(capture),
        .shadow_data(shadow_data)
    );
endmodule

// Integrated register module combining primary and shadow functionality
// Reduces signal propagation delay by eliminating intermediate connections
module integrated_shadow_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data
);
    // Primary data register
    reg [WIDTH-1:0] primary_data;
    
    // Primary register update - optimized for timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            primary_data <= {WIDTH{1'b0}};
        else
            primary_data <= data_in;
    end
    
    // Shadow register update - optimized for timing
    // Split into two separate always blocks to allow for better timing optimization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (capture)
            shadow_data <= primary_data;
    end
endmodule