//SystemVerilog
module rotate_left_shifter (
    input clk,
    input rst,
    input enable,
    input valid_in,
    output reg valid_out,
    output reg [7:0] data_out
);
    // Internal pipeline registers
    reg [7:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2;
    
    // Pre-load with pattern
    initial begin
        data_out = 8'b10101010;
        data_stage1 = 8'b10101010;
        data_stage2 = 8'b10101010;
        valid_out = 1'b0;
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
    end
    
    // Stage 1: Generate shifted data
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 8'b10101010;
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            data_stage1 <= {data_out[6:0], data_out[7]};
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Further processing (could be more complex in real designs)
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 8'b10101010;
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b10101010;
            valid_out <= 1'b0;
        end
        else if (enable) begin
            data_out <= data_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule