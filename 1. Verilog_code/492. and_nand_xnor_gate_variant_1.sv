//SystemVerilog
// Top level module with pipelined data path
module and_nand_xnor_gate (
    input wire A, B, C, D,   // 输入A, B, C, D
    input wire clk,          // 时钟输入
    input wire rst_n,        // 复位信号，低电平有效
    output wire Y            // 输出Y
);
    // Pipeline stage 1 signals - Input registration
    reg A_reg, B_reg, C_reg, D_reg;
    
    // Pipeline stage 2 signals - Logic operation results
    reg and_result_reg, nand_result_reg, A_delayed_reg;
    
    // Pipeline stage 3 signals - Final computation
    reg Y_reg;
    
    // Internal combinational signals
    wire and_result, nand_result;
    wire intermediate;
    
    // Stage 1: Register all inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 1'b0;
            B_reg <= 1'b0;
            C_reg <= 1'b0;
            D_reg <= 1'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
            C_reg <= C;
            D_reg <= D;
        end
    end
    
    // Primary logic operations (combinational)
    assign and_result = A_reg & B_reg;    // AND operation
    assign nand_result = ~(C_reg & D_reg); // NAND operation
    
    // Stage 2: Register logic operation results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_reg <= 1'b0;
            nand_result_reg <= 1'b0;
            A_delayed_reg <= 1'b0;
        end else begin
            and_result_reg <= and_result;
            nand_result_reg <= nand_result;
            A_delayed_reg <= A_reg; // Delay A to align with stage 2 results
        end
    end
    
    // Intermediate combinational logic
    assign intermediate = and_result_reg & nand_result_reg;
    
    // Stage 3: Final computation and output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= 1'b0;
        end else begin
            Y_reg <= intermediate ~^ A_delayed_reg; // XNOR operation
        end
    end
    
    // Output assignment
    assign Y = Y_reg;
    
endmodule