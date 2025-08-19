//SystemVerilog (IEEE 1364-2005)
module Matrix_NAND(
    input clk,
    input rst_n,
    
    // Input interface
    input [3:0] row,
    input [3:0] col,
    input valid_in,
    output reg ready_in,
    
    // Output interface
    output reg [7:0] mat_res,
    output reg valid_out,
    input ready_out
);
    
    // Pipeline stage signals
    reg [3:0] row_stage1, col_stage1;
    reg valid_stage1;
    
    reg [7:0] result_stage2;
    reg valid_stage2;
    
    // Pipeline control signals
    wire stage1_ready, stage2_ready;
    
    // Backward pressure logic
    assign stage2_ready = !valid_out || ready_out;
    assign stage1_ready = !valid_stage2 || stage2_ready;
    
    // First pipeline stage: Input and computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_stage1 <= 4'b0;
            col_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_in && valid_in) begin
            row_stage1 <= row;
            col_stage1 <= col;
            valid_stage1 <= 1'b1;
        end else if (valid_stage1 && stage1_ready) begin
            valid_stage1 <= 1'b0;
        end
    end

    // Input handshake control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;
        end else if (ready_in && valid_in) begin
            ready_in <= 1'b0;
        end else if (!ready_in && stage1_ready) begin
            ready_in <= 1'b1;
        end
    end
    
    // Second pipeline stage: NAND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && stage1_ready) begin
            result_stage2 <= ~({row_stage1, col_stage1} & 8'hAA);
            valid_stage2 <= 1'b1;
        end else if (valid_stage2 && stage2_ready) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Third pipeline stage: Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mat_res <= 8'b0;
            valid_out <= 1'b0;
        end else if (valid_stage2 && stage2_ready) begin
            mat_res <= result_stage2;
            valid_out <= 1'b1;
        end else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end
    
endmodule