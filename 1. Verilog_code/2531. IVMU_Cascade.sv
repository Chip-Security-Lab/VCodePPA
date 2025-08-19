module IVMU_Cascade #(parameter N=2) (
    input [N*4-1:0] casc_irq,
    output reg [3:0] highest_irq
);
    // 修改为使用Verilog标准结构
    integer i;
    reg found; // 添加标志位以代替break
    
    always @(*) begin
        highest_irq = 4'b0;
        found = 0;
        
        for (i = 0; i < N; i = i + 1) begin
            if (|casc_irq[i*4 +: 4] && !found) begin
                highest_irq = casc_irq[i*4 +: 4];
                found = 1; // 使用标志位而不是break
            end
        end
    end
endmodule