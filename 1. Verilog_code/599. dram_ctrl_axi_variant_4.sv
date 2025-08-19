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
    reg [31:0] awaddr_stage1;
    reg awready_stage1;
    reg awready_stage2;

    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;

    // 流水线输出
    assign awready = awready_stage2;

    // 第一级流水线
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awvalid_stage1 <= 1'b0;
            awaddr_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            awvalid_stage1 <= awvalid;
            awaddr_stage1 <= awaddr;
            valid_stage1 <= awvalid;
        end
    end

    // 第二级流水线
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready_stage1 <= 1'b0;
            awready_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            awready_stage1 <= valid_stage1;
            awready_stage2 <= awready_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

endmodule