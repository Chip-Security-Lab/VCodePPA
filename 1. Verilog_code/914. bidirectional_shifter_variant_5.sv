//SystemVerilog
module bidirectional_shifter(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    input wire [4:0] shift_amount,
    input wire direction,  // 0: left, 1: right
    output reg [31:0] result
);

    // Pipeline registers
    reg [31:0] stage0_reg, stage1_reg, stage2_reg, stage3_reg;
    reg [4:0] shift_amount_reg;
    reg direction_reg;
    
    // Stage 0: 1-bit shift with register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_reg <= 32'b0;
            shift_amount_reg <= 5'b0;
            direction_reg <= 1'b0;
        end else begin
            stage0_reg <= shift_amount[0] ? 
                         (direction ? {1'b0, data_in[31:1]} : {data_in[30:0], 1'b0}) : 
                         data_in;
            shift_amount_reg <= shift_amount;
            direction_reg <= direction;
        end
    end
    
    // Stage 1: 2-bit shift with register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= 32'b0;
        end else begin
            stage1_reg <= shift_amount_reg[1] ? 
                         (direction_reg ? {2'b00, stage0_reg[31:2]} : {stage0_reg[29:0], 2'b00}) : 
                         stage0_reg;
        end
    end
    
    // Stage 2: 4-bit shift with register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_reg <= 32'b0;
        end else begin
            stage2_reg <= shift_amount_reg[2] ? 
                         (direction_reg ? {4'b0000, stage1_reg[31:4]} : {stage1_reg[27:0], 4'b0000}) : 
                         stage1_reg;
        end
    end
    
    // Stage 3: 8-bit shift with register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_reg <= 32'b0;
        end else begin
            stage3_reg <= shift_amount_reg[3] ? 
                         (direction_reg ? {8'b00000000, stage2_reg[31:8]} : {stage2_reg[23:0], 8'b00000000}) : 
                         stage2_reg;
        end
    end
    
    // Final stage: 16-bit shift with output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'b0;
        end else begin
            result <= shift_amount_reg[4] ? 
                     (direction_reg ? {16'b0000000000000000, stage3_reg[31:16]} : {stage3_reg[15:0], 16'b0000000000000000}) : 
                     stage3_reg;
        end
    end

endmodule