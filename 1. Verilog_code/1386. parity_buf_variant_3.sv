//SystemVerilog
// Top-level module
module parity_buf #(
    parameter DW = 9
) (
    input wire clk,
    input wire en,
    input wire [DW-2:0] data_in,
    output wire [DW-1:0] data_out
);
    // Internal connections
    wire parity_bit_stage1;
    wire parity_bit_stage2;
    wire [DW-2:0] data_stage1;
    wire [DW-2:0] data_stage2;
    reg en_stage1, en_stage2;
    
    // Pipeline stage control
    always @(posedge clk) begin
        en_stage1 <= en;
        en_stage2 <= en_stage1;
    end
    
    // Multi-stage parity generator instance
    parity_generator #(
        .WIDTH(DW-1)
    ) parity_gen_inst (
        .clk(clk),
        .data(data_in),
        .parity_stage1(parity_bit_stage1),
        .parity_stage2(parity_bit_stage2)
    );
    
    // Data pipeline registers
    pipeline_data_registers #(
        .DW(DW-1)
    ) data_pipeline_inst (
        .clk(clk),
        .data_in(data_in),
        .data_stage1(data_stage1),
        .data_stage2(data_stage2)
    );
    
    // Data output register instance
    data_output_register #(
        .DW(DW)
    ) data_reg_inst (
        .clk(clk),
        .en(en_stage2),
        .data_in(data_stage2),
        .parity_bit(parity_bit_stage2),
        .data_out(data_out)
    );
    
endmodule

// Multi-stage parity generator module
module parity_generator #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire [WIDTH-1:0] data,
    output reg parity_stage1,
    output reg parity_stage2
);
    // Stage 1: Calculate partial parity for lower half
    wire parity_lower_half;
    wire parity_upper_half;
    
    // Split data in half for parallel processing
    assign parity_lower_half = ^data[WIDTH/2-1:0];
    assign parity_upper_half = ^data[WIDTH-1:WIDTH/2];
    
    // Pipeline stage 1: Register partial results
    always @(posedge clk) begin
        parity_stage1 <= parity_lower_half ^ parity_upper_half;
    end
    
    // Pipeline stage 2: Final parity calculation
    always @(posedge clk) begin
        parity_stage2 <= parity_stage1;
    end
    
endmodule

// Pipeline data registers
module pipeline_data_registers #(
    parameter DW = 8
) (
    input wire clk,
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] data_stage1,
    output reg [DW-1:0] data_stage2
);
    // Pipeline stage 1
    always @(posedge clk) begin
        data_stage1 <= data_in;
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        data_stage2 <= data_stage1;
    end
    
endmodule

// Data output register module
module data_output_register #(
    parameter DW = 9
) (
    input wire clk,
    input wire en,
    input wire [DW-2:0] data_in,
    input wire parity_bit,
    output reg [DW-1:0] data_out
);
    // Register the data with parity bit
    always @(posedge clk) begin
        if (en) begin
            data_out <= {parity_bit, data_in};
        end
    end
    
endmodule