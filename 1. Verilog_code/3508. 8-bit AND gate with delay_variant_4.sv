//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: and_gate_8_delay_top.v
// Author: Restructured Design
// Description: Top-level module for 8-bit AND operation with pipelined delay
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module and_gate_8_delay_top (
    input  wire        clk,        // System clock
    input  wire        rst_n,      // Active low reset
    input  wire [7:0]  a,          // 8-bit input A
    input  wire [7:0]  b,          // 8-bit input B
    output wire [7:0]  y           // 8-bit output Y
);

    // Data flow pipeline stages
    wire [7:0] stage1_a_reg;
    wire [7:0] stage1_b_reg;
    wire [7:0] stage2_and_result;
    wire [7:0] stage3_delayed_data;

    // Input registration stage
    input_register_stage input_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .a_in         (a),
        .b_in         (b),
        .a_reg        (stage1_a_reg),
        .b_reg        (stage1_b_reg)
    );
    
    // AND operation stage
    and_operation_unit and_unit (
        .clk          (clk),
        .rst_n        (rst_n),
        .in_a         (stage1_a_reg),
        .in_b         (stage1_b_reg),
        .and_result   (stage2_and_result)
    );
    
    // Output delay stage
    delay_unit #(
        .PIPELINE_STAGES (2),
        .DATA_WIDTH     (8)
    ) delay_unit_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (stage2_and_result),
        .data_out       (y)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: input_register_stage.v
// Description: Input registration stage to improve timing
///////////////////////////////////////////////////////////////////////////////

module input_register_stage (
    input  wire        clk,        // System clock
    input  wire        rst_n,      // Active low reset
    input  wire [7:0]  a_in,       // Raw input A
    input  wire [7:0]  b_in,       // Raw input B
    output reg  [7:0]  a_reg,      // Registered input A
    output reg  [7:0]  b_reg       // Registered input B
);

    // Register inputs to break timing path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h00;
            b_reg <= 8'h00;
        end else begin
            a_reg <= a_in;
            b_reg <= b_in;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: and_operation_unit.v
// Description: Pipelined AND operation unit
///////////////////////////////////////////////////////////////////////////////

module and_operation_unit (
    input  wire        clk,        // System clock
    input  wire        rst_n,      // Active low reset
    input  wire [7:0]  in_a,       // Registered input A
    input  wire [7:0]  in_b,       // Registered input B
    output reg  [7:0]  and_result  // Registered AND result
);

    // Perform AND operation and register the result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 8'h00;
        end else begin
            and_result <= in_a & in_b;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: delay_unit.v
// Description: Parameterized pipeline delay unit with multiple stages
///////////////////////////////////////////////////////////////////////////////

module delay_unit #(
    parameter PIPELINE_STAGES = 2,      // Number of pipeline stages
    parameter DATA_WIDTH      = 8       // Data width
)(
    input  wire                   clk,      // System clock
    input  wire                   rst_n,    // Active low reset
    input  wire [DATA_WIDTH-1:0]  data_in,  // Input data
    output wire [DATA_WIDTH-1:0]  data_out  // Delayed output data
);

    // Pipeline registers
    reg [DATA_WIDTH-1:0] pipe_regs [PIPELINE_STAGES-1:0];
    
    integer i;
    
    // Pipeline stage logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                pipe_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            pipe_regs[0] <= data_in;
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                pipe_regs[i] <= pipe_regs[i-1];
            end
        end
    end
    
    // Connect the last stage to output
    assign data_out = pipe_regs[PIPELINE_STAGES-1];

endmodule