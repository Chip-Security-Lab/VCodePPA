module log_barrel_shifter (
    input            clk,
    input            rst_n,
    input  [15:0]    data_i,
    input  [3:0]     shamt,
    output reg [15:0] data_o
);
    // Intermediate wires for logarithmic barrel shifter stages
    reg [15:0] stage_data [4:0]; // One for input, 4 for stages
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o <= 16'b0;
            stage_data[0] <= 16'b0;
        end else begin
            // Input stage
            stage_data[0] <= data_i;
            
            // Stage 1: shift by 0 or 1
            stage_data[1] <= shamt[0] ? {stage_data[0][14:0], 1'b0} : stage_data[0];
            
            // Stage 2: shift by 0 or 2
            stage_data[2] <= shamt[1] ? {stage_data[1][13:0], 2'b0} : stage_data[1];
            
            // Stage 3: shift by 0 or 4
            stage_data[3] <= shamt[2] ? {stage_data[2][11:0], 4'b0} : stage_data[2];
            
            // Stage 4: shift by 0 or 8
            stage_data[4] <= shamt[3] ? {stage_data[3][7:0], 8'b0} : stage_data[3];
            
            // Final output
            data_o <= stage_data[4];
        end
    end
endmodule