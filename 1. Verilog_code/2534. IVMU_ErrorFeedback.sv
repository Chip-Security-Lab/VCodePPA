module IVMU_ErrorFeedback (
    input clk, 
    input err_irq,
    output reg [1:0] err_code,
    output reg err_valid // 修改为reg类型
);
    always @(posedge clk) begin
        err_valid <= err_irq;
        err_code <= {err_irq, 1'b0};
    end
endmodule