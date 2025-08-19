//SystemVerilog
`timescale 1ns / 1ps
// IEEE 1364-2005 Verilog standard
module p2s_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] parallel_in,
    input wire load_parallel,
    input wire shift_en,
    output wire serial_out,
    output reg [WIDTH-1:0] shadow_data
);
    // Optimized shift register implementation
    reg [WIDTH-1:0] shift_reg;
    
    // Reset logic for shift register
    always @(negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WIDTH{1'b0}};
        end
    end
    
    // Load parallel data logic
    always @(posedge clk) begin
        if (rst_n && load_parallel) begin
            shift_reg <= parallel_in;
        end
    end
    
    // Shift operation logic
    always @(posedge clk) begin
        if (rst_n && shift_en && !load_parallel) begin
            shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
        end
    end
    
    // Reset logic for shadow register
    always @(negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
        end
    end
    
    // Load parallel data to shadow register
    always @(posedge clk) begin
        if (rst_n && load_parallel) begin
            shadow_data <= parallel_in;
        end
    end
    
    // Direct wire assignment for faster logic path
    assign serial_out = shift_reg[WIDTH-1];
    
endmodule