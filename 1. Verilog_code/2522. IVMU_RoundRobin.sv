module IVMU_RoundRobin #(parameter CH=4) (
    input [CH-1:0] irq,
    output reg [$clog2(CH)-1:0] current_ch
);
    // 修改为使用Verilog标准操作
    always @(*) begin
        casez(irq)
            4'b1???: current_ch = 2'd3;
            4'b01??: current_ch = 2'd2;
            4'b001?: current_ch = 2'd1;
            4'b0001: current_ch = 2'd0;
            default: current_ch = 2'd0;
        endcase
    end
endmodule