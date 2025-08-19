//SystemVerilog
module dram_ctrl_axi #(
    parameter AXI_DATA_WIDTH = 64
)(
    input aclk,
    input aresetn,
    // AXI4接口
    input [31:0] awaddr,
    input awvalid,
    output reg awready
);

    // 地址相位处理
    always @(posedge aclk or negedge aresetn) begin
        awready <= !aresetn ? 1'b0 : awvalid;
    end

endmodule