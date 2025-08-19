//SystemVerilog
module dram_ctrl_axi #(
    parameter AXI_DATA_WIDTH = 64
)(
    input aclk,
    input aresetn,
    input [31:0] awaddr,
    input awvalid,
    output awready,
    output reg valid_stage1,
    output reg valid_stage2,
    output reg [31:0] addr_stage1,
    output reg [31:0] addr_stage2
);

    // 流水线就绪信号
    wire stage2_ready = !valid_stage2;
    wire stage1_ready = !valid_stage1 || stage2_ready;
    
    // 输出赋值
    assign awready = stage1_ready;
    
    // 流水线第一级
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            {valid_stage1, addr_stage1} <= {1'b0, 32'b0};
        end else if(stage1_ready) begin
            {valid_stage1, addr_stage1} <= {awvalid, awaddr};
        end
    end
    
    // 流水线第二级
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            {valid_stage2, addr_stage2} <= {1'b0, 32'b0};
        end else if(stage2_ready) begin
            {valid_stage2, addr_stage2} <= {valid_stage1, addr_stage1};
        end
    end

endmodule