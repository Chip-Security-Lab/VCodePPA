//SystemVerilog
//IEEE 1364-2005 (SystemVerilog)
module AsyncReset_AND(
    input logic rst_n,
    input logic [3:0] src1, src2,
    output logic [3:0] q
);
    // Pipeline stage signals
    logic [3:0] stage1_src1_reg, stage1_src2_reg;
    logic [3:0] stage2_and_result;
    logic stage1_rst_n, stage2_rst_n;
    
    // Stage 1: Register inputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_src1_reg <= 4'b0;
            stage1_src2_reg <= 4'b0;
            stage1_rst_n <= 1'b0;
        end else begin
            stage1_src1_reg <= src1;
            stage1_src2_reg <= src2;
            stage1_rst_n <= rst_n;
        end
    end
    
    // Stage 2: Logic operation with registered inputs
    logic [3:0] and_result;
    
    LogicOperation_Pipelined logic_op (
        .clk(clk),
        .rst_n(stage1_rst_n),
        .in1(stage1_src1_reg),
        .in2(stage1_src2_reg),
        .out(and_result)
    );
    
    // Register the logic operation result
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_result <= 4'b0;
            stage2_rst_n <= 1'b0;
        end else begin
            stage2_and_result <= and_result;
            stage2_rst_n <= stage1_rst_n;
        end
    end
    
    // Final stage: Reset control with registered inputs
    ResetControl_Pipelined reset_ctrl (
        .clk(clk),
        .rst_n(stage2_rst_n),
        .data_in(stage2_and_result),
        .data_out(q)
    );
    
endmodule

// Pipelined logical operation submodule
module LogicOperation_Pipelined(
    input logic clk,
    input logic rst_n,
    input logic [3:0] in1,
    input logic [3:0] in2,
    output logic [3:0] out
);
    // Split the AND operation into smaller parts for timing improvement
    logic [1:0] upper_result, lower_result;
    
    // Perform bitwise AND operation in pipeline stages
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_result <= 2'b0;
            lower_result <= 2'b0;
        end else begin
            upper_result <= in1[3:2] & in2[3:2];
            lower_result <= in1[1:0] & in2[1:0];
        end
    end
    
    // Combine results
    assign out = {upper_result, lower_result};
    
endmodule

// Pipelined reset control submodule
module ResetControl_Pipelined(
    input logic clk,
    input logic rst_n,
    input logic [3:0] data_in,
    output logic [3:0] data_out
);
    // Register output with synchronous reset logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 4'b0000;
        end else begin
            data_out <= data_in;
        end
    end
    
endmodule