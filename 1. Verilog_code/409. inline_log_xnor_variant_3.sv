//SystemVerilog
//-----------------------------------------------------------------------------
// Title       : XNOR Logic Operation - Top Module
// Design      : Fully Pipelined XNOR Implementation with Enhanced Datapath
// Standard    : IEEE 1364-2005
//-----------------------------------------------------------------------------

module inline_log_xnor (
    input  wire        clk,         // Clock input
    input  wire        rst_n,       // Active-low reset
    input  wire        a,           // First input operand
    input  wire        b,           // Second input operand
    input  wire        valid_in,    // Input data valid
    output wire        valid_out,   // Output data valid
    output wire        ready_in,    // Ready to accept new input
    output wire        out          // XNOR result output
);

    // Pipeline control signals
    wire valid_stage1, valid_stage2, valid_stage3;
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // Data pipeline stage signals
    wire stage1_compare_result;
    reg  stage2_pipeline_reg;
    
    // Pipeline ready/valid logic
    assign ready_in = ready_stage1;
    assign valid_out = valid_stage3;
    
    // Stage 1: Input comparison datapath with valid/ready flow control
    equality_comparator equality_comp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .operand_a(a),
        .operand_b(b),
        .valid_in(valid_in),
        .ready_out(ready_stage1),
        .valid_out(valid_stage1),
        .ready_in(ready_stage2),
        .equal_result(stage1_compare_result)
    );
    
    // Stage 2: Pipeline register to break long datapath with flow control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_pipeline_reg <= 1'b0;
        else if (valid_stage1 && ready_stage2)
            stage2_pipeline_reg <= stage1_compare_result;
    end
    
    // Stage 2 flow control
    reg valid_stage2_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_stage2_reg <= 1'b0;
        else if (ready_stage2)
            valid_stage2_reg <= valid_stage1;
    end
    
    assign valid_stage2 = valid_stage2_reg;
    assign ready_stage2 = !valid_stage2_reg || ready_stage3;
    
    // Stage 3: Output driver datapath with flow control
    output_driver output_driver_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(stage2_pipeline_reg),
        .valid_in(valid_stage2),
        .ready_out(ready_stage3),
        .valid_out(valid_stage3),
        .data_out(out)
    );

endmodule

//-----------------------------------------------------------------------------
// Equality Comparator Submodule - Stage 1 Pipeline
// Performs the comparison between two input operands with registered inputs
// and pipeline flow control
//-----------------------------------------------------------------------------
module equality_comparator (
    input  wire clk,
    input  wire rst_n,
    input  wire operand_a,
    input  wire operand_b,
    input  wire valid_in,
    output wire ready_out,
    output wire valid_out,
    input  wire ready_in,
    output wire equal_result
);
    // Registered input operands to improve timing
    reg operand_a_stage1, operand_b_stage1;
    reg operand_a_stage2, operand_b_stage2;
    
    // Intermediate stage signals
    reg equal_stage1;
    reg equal_stage2;
    
    // Pipeline valid signals
    reg valid_stage1_reg;
    reg valid_stage2_reg;
    
    // Stage flow control
    wire ready_stage1 = !valid_stage1_reg || ready_stage2;
    wire ready_stage2 = !valid_stage2_reg || ready_in;
    
    // Stage 1 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a_stage1 <= 1'b0;
            operand_b_stage1 <= 1'b0;
            valid_stage1_reg <= 1'b0;
        end
        else if (ready_stage1) begin
            operand_a_stage1 <= operand_a;
            operand_b_stage1 <= operand_b;
            valid_stage1_reg <= valid_in;
        end
    end
    
    // Stage 1 computation
    wire stage1_result = (operand_a_stage1 == operand_b_stage1);
    
    // Stage 2 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal_stage1 <= 1'b0;
            valid_stage2_reg <= 1'b0;
        end
        else if (ready_stage2) begin
            equal_stage1 <= stage1_result;
            valid_stage2_reg <= valid_stage1_reg;
        end
    end
    
    // Output assignments
    assign equal_result = equal_stage1;
    assign valid_out = valid_stage2_reg;
    assign ready_out = ready_stage1;
    
endmodule

//-----------------------------------------------------------------------------
// Output Driver Submodule - Stage 3 Pipeline
// Processes and drives the final result to the output port with flow control
//-----------------------------------------------------------------------------
module output_driver (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    input  wire valid_in,
    output wire ready_out,
    output reg  valid_out,
    output reg  data_out
);
    // Output stage flow control
    assign ready_out = 1'b1;  // Always ready to receive new data
    
    // Registered output to break timing path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end

endmodule