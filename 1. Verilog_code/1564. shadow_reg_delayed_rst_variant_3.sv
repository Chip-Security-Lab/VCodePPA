//SystemVerilog
module shadow_reg_delayed_rst #(parameter DW=16, DELAY=3) (
    input clk, rst_in,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // Pipelined reset shift register
    reg [DELAY-1:0] rst_sr;
    // Pipeline stages for data
    reg [DW-1:0] data_stage1;
    reg [DW-1:0] data_stage2;
    // Valid signals for pipeline control
    reg valid_stage1, valid_stage2;
    
    always @(posedge clk) begin
        // Reset shift register pipeline
        rst_sr <= {rst_sr[DELAY-2:0], rst_in};
        
        // First pipeline stage
        if(rst_sr[0]) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            data_stage1 <= data_in;
            valid_stage1 <= 1;
        end
        
        // Second pipeline stage
        if(rst_sr[1]) begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
        
        // Final output stage
        if(rst_sr[2]) begin
            data_out <= 0;
        end
        else if(valid_stage2) begin
            data_out <= data_stage2;
        end
    end
endmodule