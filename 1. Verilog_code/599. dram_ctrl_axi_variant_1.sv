//SystemVerilog
module dram_ctrl_axi #(
    parameter AXI_DATA_WIDTH = 64
)(
    input aclk,
    input aresetn,
    // AXI4接口
    input [31:0] awaddr,
    input awvalid,
    output awready
);

    // 流水线寄存器
    reg awvalid_stage1;
    reg awvalid_stage2;
    reg awready_reg;
    
    // 流水线控制信号
    wire pipeline_enable;
    assign pipeline_enable = 1'b1;
    
    // 地址相位处理 - 第一级流水线
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            awvalid_stage1 <= 1'b0;
            awvalid_stage2 <= 1'b0;
            awready_reg <= 1'b0;
        end else if(pipeline_enable) begin
            awvalid_stage1 <= awvalid;
            awvalid_stage2 <= awvalid_stage1;
            awready_reg <= awvalid_stage2;
        end
    end
    
    assign awready = awready_reg;
    
endmodule