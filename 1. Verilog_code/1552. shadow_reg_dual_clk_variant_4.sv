//SystemVerilog
module shadow_reg_dual_clk_pipelined #(parameter DW=16) (
    input main_clk, shadow_clk,
    input load, 
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    input rst_n
);
    // Pipeline stages
    reg [DW-1:0] shadow_storage_stage1;
    reg [DW-1:0] shadow_storage_stage2;
    reg load_stage1;
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Main clock domain
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_storage_stage1 <= {DW{1'b0}};
            load_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (load) begin
                shadow_storage_stage1 <= din;
                load_stage1 <= 1'b1;
                valid_stage1 <= 1'b1;
            end else begin
                load_stage1 <= 1'b0;
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Shadow clock domain
    always @(posedge shadow_clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_storage_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                shadow_storage_stage2 <= shadow_storage_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge shadow_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
        end else begin
            if (valid_stage2) begin
                dout <= shadow_storage_stage2;
            end
        end
    end
endmodule