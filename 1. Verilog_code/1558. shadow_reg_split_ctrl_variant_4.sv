//SystemVerilog
module shadow_reg_split_ctrl #(parameter DW=12, parameter PIPELINE_STAGES=3) (
    input clk,
    input rst_n,
    input load,
    input update,
    input [DW-1:0] datain,
    output reg [DW-1:0] dataout,
    output reg valid_out
);
    // 流水线寄存器
    reg [DW-1:0] shadow_stage1;
    reg [DW-1:0] shadow_stage2;
    reg [DW-1:0] shadow_stage3;
    
    // 流水线控制信号
    reg load_stage1, load_stage2, load_stage3;
    reg update_stage1, update_stage2, update_stage3;
    reg [DW-1:0] datain_stage1, datain_stage2, datain_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_stage1 <= 1'b0;
            update_stage1 <= 1'b0;
            datain_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            load_stage1 <= load;
            update_stage1 <= update;
            datain_stage1 <= datain;
            valid_stage1 <= load || update;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_stage1 <= {DW{1'b0}};
            load_stage2 <= 1'b0;
            update_stage2 <= 1'b0;
            datain_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (load_stage1) shadow_stage1 <= datain_stage1;
            load_stage2 <= load_stage1;
            update_stage2 <= update_stage1;
            datain_stage2 <= datain_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_stage2 <= {DW{1'b0}};
            load_stage3 <= 1'b0;
            update_stage3 <= 1'b0;
            datain_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (load_stage2) shadow_stage2 <= datain_stage2;
            load_stage3 <= load_stage2;
            update_stage3 <= update_stage2;
            datain_stage3 <= datain_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_stage3 <= {DW{1'b0}};
            dataout <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (load_stage3) shadow_stage3 <= datain_stage3;
            if (update_stage3) dataout <= shadow_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule