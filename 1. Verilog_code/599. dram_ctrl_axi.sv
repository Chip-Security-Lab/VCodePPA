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
    // 地址相位处理
    reg awready_reg;
    assign awready = awready_reg;
    
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            awready_reg <= 0;
        end else begin
            awready_reg <= awvalid;
        end
    end
endmodule
