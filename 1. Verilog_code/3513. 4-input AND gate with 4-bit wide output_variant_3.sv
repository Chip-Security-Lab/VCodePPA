//SystemVerilog
//===================================================================
// Module Name: and_gate_4bit_top
// Description: Top-level module for 4-bit 4-input AND operation
//              with pipelined data path for improved timing
//===================================================================
module and_gate_4bit_top (
    input  wire        clk,         // System clock
    input  wire        rst_n,       // Active-low reset
    input  wire [3:0]  a_data,      // 4-bit input A
    input  wire [3:0]  b_data,      // 4-bit input B
    input  wire [3:0]  c_data,      // 4-bit input C
    input  wire [3:0]  d_data,      // 4-bit input D
    output wire [3:0]  result_data  // 4-bit output result
);

    // Internal pipeline registers
    reg [3:0] a_data_reg, b_data_reg;
    reg [3:0] c_data_reg, d_data_reg;
    reg [3:0] ab_result;
    reg [3:0] cd_result;
    reg [3:0] final_result;

    // First pipeline stage: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_data_reg <= 4'b0;
            b_data_reg <= 4'b0;
            c_data_reg <= 4'b0;
            d_data_reg <= 4'b0;
        end else begin
            a_data_reg <= a_data;
            b_data_reg <= b_data;
            c_data_reg <= c_data;
            d_data_reg <= d_data;
        end
    end

    // Second pipeline stage: Compute partial AND results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_result <= 4'b0;
            cd_result <= 4'b0;
        end else begin
            ab_result <= a_data_reg & b_data_reg;
            cd_result <= c_data_reg & d_data_reg;
        end
    end

    // Third pipeline stage: Compute final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result <= 4'b0;
        end else begin
            final_result <= ab_result & cd_result;
        end
    end

    // Output assignment
    assign result_data = final_result;

endmodule