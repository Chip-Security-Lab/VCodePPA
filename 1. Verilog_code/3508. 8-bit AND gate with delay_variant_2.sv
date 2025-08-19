//SystemVerilog
// Top-level module: 8-bit AND gate with pipelined architecture
module and_gate_8_delay (
    input  wire        clk,       // System clock
    input  wire        rst_n,     // Active low reset
    input  wire [7:0]  a,         // 8-bit input A
    input  wire [7:0]  b,         // 8-bit input B
    output wire [7:0]  y          // 8-bit output Y
);
    // Data flow control signals
    wire [7:0] and_result;        // Combinational AND result
    reg  [7:0] pipeline_reg;      // Pipeline register for timing optimization
    
    // Instantiate the datapath module
    and_datapath and_datapath_inst (
        .a_operand(a),
        .b_operand(b),
        .and_result(and_result)
    );
    
    // Pipeline register for improved timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_reg <= 8'b0;
        end else begin
            pipeline_reg <= and_result;
        end
    end
    
    // Output assignment
    assign y = pipeline_reg;
    
endmodule

// Datapath module containing the AND operation logic
module and_datapath (
    input  wire [7:0] a_operand,   // 8-bit input operand A
    input  wire [7:0] b_operand,   // 8-bit input operand B
    output wire [7:0] and_result   // 8-bit AND result
);
    // Instantiate four 2-bit AND processing units
    and_processing_unit and_pu0 (
        .a_slice(a_operand[1:0]),
        .b_slice(b_operand[1:0]),
        .y_slice(and_result[1:0])
    );
    
    and_processing_unit and_pu1 (
        .a_slice(a_operand[3:2]),
        .b_slice(b_operand[3:2]),
        .y_slice(and_result[3:2])
    );
    
    and_processing_unit and_pu2 (
        .a_slice(a_operand[5:4]),
        .b_slice(b_operand[5:4]),
        .y_slice(and_result[5:4])
    );
    
    and_processing_unit and_pu3 (
        .a_slice(a_operand[7:6]),
        .b_slice(b_operand[7:6]),
        .y_slice(and_result[7:6])
    );
    
endmodule

// 2-bit AND processing unit with optimized timing
module and_processing_unit (
    input  wire [1:0] a_slice,    // 2-bit slice of input A
    input  wire [1:0] b_slice,    // 2-bit slice of input B
    output reg  [1:0] y_slice     // 2-bit slice of output Y
);
    // Internal signals for timing control
    reg [1:0] and_op_result;
    
    // Compute AND operation with delay model
    always @(a_slice, b_slice) begin
        and_op_result = a_slice & b_slice;
        #5 y_slice = and_op_result;  // 5-time unit delay preserved
    end
endmodule