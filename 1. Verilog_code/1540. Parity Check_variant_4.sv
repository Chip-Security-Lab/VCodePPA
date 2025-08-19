//SystemVerilog
module parity_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update,
    output reg [WIDTH-1:0] shadow_data,
    output reg parity_error
);
    // Direct parity calculation from input
    wire input_parity = ^data_in;
    
    // Registered input data and its parity
    reg [WIDTH-1:0] reg_data_in;
    reg reg_input_parity;
    
    // Work register (now second stage)
    reg [WIDTH-1:0] work_reg;
    reg work_parity;
    
    // First stage: register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_in <= 0;
            reg_input_parity <= 0;
        end else if (update) begin
            reg_data_in <= data_in;
            reg_input_parity <= input_parity;
        end
    end
    
    // Second stage: work registers 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_reg <= 0;
            work_parity <= 0;
        end else if (update) begin
            work_reg <= reg_data_in;
            work_parity <= reg_input_parity;
        end
    end
    
    // Third stage: shadow registers and error detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            parity_error <= 0;
        end else if (update) begin
            shadow_data <= work_reg;
            parity_error <= (^work_reg) != work_parity;
        end
    end
endmodule