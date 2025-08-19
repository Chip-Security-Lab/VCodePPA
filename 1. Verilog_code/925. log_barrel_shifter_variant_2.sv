//SystemVerilog
module log_barrel_shifter (
    input            clk,
    input            rst_n,
    input  [15:0]    data_i,
    input  [3:0]     shamt,
    output reg [15:0] data_o
);
    // Intermediate wires for logarithmic barrel shifter stages
    reg [15:0] stage_data [4:0]; // One for input, 4 for stages
    
    // Buffered control signals to reduce fanout
    reg [3:0] shamt_buf1, shamt_buf2;
    
    // Intermediate stage data buffers to balance load
    reg [15:0] stage_data_buf1 [1:0]; // Buffers for stages 1 and 2
    reg [15:0] stage_data_buf2 [1:0]; // Buffers for stages 3 and 4
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shamt_buf1 <= 4'b0;
            shamt_buf2 <= 4'b0;
            stage_data[0] <= 16'b0;
            stage_data_buf1[0] <= 16'b0;
            stage_data_buf1[1] <= 16'b0;
            stage_data_buf2[0] <= 16'b0;
            stage_data_buf2[1] <= 16'b0;
            data_o <= 16'b0;
        end else begin
            // Buffer the control signals to reduce fanout
            shamt_buf1 <= shamt;
            shamt_buf2 <= shamt_buf1;
            
            // Input stage
            stage_data[0] <= data_i;
            
            // Stage 1: shift by 0 or 1 (using first buffer)
            stage_data[1] <= shamt_buf1[0] ? {stage_data[0][14:0], 1'b0} : stage_data[0];
            stage_data_buf1[0] <= stage_data[1];
            
            // Stage 2: shift by 0 or 2 (using buffered data)
            stage_data[2] <= shamt_buf1[1] ? {stage_data_buf1[0][13:0], 2'b0} : stage_data_buf1[0];
            stage_data_buf1[1] <= stage_data[2];
            
            // Stage 3: shift by 0 or 4 (using second buffer)
            stage_data[3] <= shamt_buf2[2] ? {stage_data_buf1[1][11:0], 4'b0} : stage_data_buf1[1];
            stage_data_buf2[0] <= stage_data[3];
            
            // Stage 4: shift by 0 or 8 (using buffered data)
            stage_data[4] <= shamt_buf2[3] ? {stage_data_buf2[0][7:0], 8'b0} : stage_data_buf2[0];
            stage_data_buf2[1] <= stage_data[4];
            
            // Final output
            data_o <= stage_data_buf2[1];
        end
    end
endmodule