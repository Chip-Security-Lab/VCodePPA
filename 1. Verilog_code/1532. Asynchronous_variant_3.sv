//SystemVerilog
// IEEE 1364-2005 Verilog standard
module async_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shadow_en,
    output reg [WIDTH-1:0] shadow_out
);
    reg [WIDTH-1:0] main_reg;
    reg [WIDTH-1:0] shadow_reg;
    reg [WIDTH-1:0] main_reg_pipe;
    reg shadow_en_pipe;
    reg shadow_en_pipe2;
    reg [WIDTH-1:0] next_shadow_out;
    
    // Main register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Pipeline stage to break combinational path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_pipe <= 0;
            shadow_en_pipe <= 0;
            shadow_en_pipe2 <= 0;
        end else begin
            main_reg_pipe <= main_reg;
            shadow_en_pipe <= shadow_en;
            shadow_en_pipe2 <= shadow_en_pipe;
        end
    end
    
    // Store shadow value when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_reg <= 0;
        else if (shadow_en_pipe)
            shadow_reg <= main_reg_pipe;
    end
    
    // Pre-compute next output value (pulled before the register)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            next_shadow_out <= 0;
        else
            next_shadow_out <= shadow_en_pipe ? main_reg_pipe : shadow_reg;
    end
    
    // Final output register (moved from after mux to after pre-computation)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= 0;
        else
            shadow_out <= next_shadow_out;
    end
endmodule