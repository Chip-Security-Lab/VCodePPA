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
    
    // Buffered shamt signals to reduce fanout
    reg [3:0] shamt_buf1, shamt_buf2;
    
    // Buffered stage_data for critical paths
    reg [15:0] stage_data_buf1 [3:0];
    reg [15:0] stage_data_buf2 [3:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o <= 16'b0;
            stage_data[0] <= 16'b0;
            shamt_buf1 <= 4'b0;
            shamt_buf2 <= 4'b0;
        end else begin
            // Buffer shamt to reduce fanout
            shamt_buf1 <= shamt;
            shamt_buf2 <= shamt_buf1;
            
            // Input stage
            stage_data[0] <= data_i;
            
            // Buffer stage_data for balanced loading
            stage_data_buf1[0] <= stage_data[0];
            stage_data_buf2[0] <= stage_data[0];
            
            // Stage 1: shift by 0 or 1 (use buffered signals)
            stage_data[1] <= shamt_buf1[0] ? {stage_data_buf1[0][14:0], 1'b0} : stage_data_buf2[0];
            
            // Buffer stage 1 output
            stage_data_buf1[1] <= stage_data[1];
            stage_data_buf2[1] <= stage_data[1];
            
            // Stage 2: shift by 0 or 2
            stage_data[2] <= shamt_buf1[1] ? {stage_data_buf1[1][13:0], 2'b0} : stage_data_buf2[1];
            
            // Buffer stage 2 output
            stage_data_buf1[2] <= stage_data[2];
            stage_data_buf2[2] <= stage_data[2];
            
            // Stage 3: shift by 0 or 4
            stage_data[3] <= shamt_buf2[2] ? {stage_data_buf1[2][11:0], 4'b0} : stage_data_buf2[2];
            
            // Buffer stage 3 output
            stage_data_buf1[3] <= stage_data[3];
            stage_data_buf2[3] <= stage_data[3];
            
            // Stage 4: shift by 0 or 8
            stage_data[4] <= shamt_buf2[3] ? {stage_data_buf1[3][7:0], 8'b0} : stage_data_buf2[3];
            
            // Final output
            data_o <= stage_data[4];
        end
    end
endmodule