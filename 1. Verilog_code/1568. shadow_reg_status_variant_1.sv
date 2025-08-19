//SystemVerilog
module shadow_reg_status #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid
);
    // Pipeline stage registers
    reg [DW-1:0] shadow_reg_stage1;
    reg [DW-1:0] shadow_reg_stage2;
    reg valid_stage1;
    reg valid_stage2;
    reg en_stage1;
    
    // Stage 1: Input capture and control signal registration
    always @(posedge clk) begin
        if (rst) begin
            shadow_reg_stage1 <= {DW{1'b0}};
            en_stage1 <= 1'b0;
        end else begin
            shadow_reg_stage1 <= data_in;
            en_stage1 <= en;
        end
    end
    
    // Stage 2: Process control logic and prepare output data
    always @(posedge clk) begin
        if (rst) begin
            shadow_reg_stage2 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            shadow_reg_stage2 <= shadow_reg_stage1;
            valid_stage1 <= ~en_stage1;
        end
    end
    
    // Stage 3: Final output generation
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {DW{1'b0}};
            valid <= 1'b0;
        end else begin
            if (~en_stage1) begin
                data_out <= shadow_reg_stage2;
            end
            valid <= valid_stage1;
        end
    end
endmodule