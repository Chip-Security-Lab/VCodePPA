//SystemVerilog
module shadow_reg_multi_layer #(parameter DW=8, DEPTH=3) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow [0:DEPTH-1];
    reg [1:0] ptr, next_ptr;
    
    // 拆分组合逻辑，预计算下一个指针值
    always @(*) begin
        next_ptr = ptr;
        if(en) begin
            next_ptr = (ptr == DEPTH-1) ? 0 : ptr + 1;
        end
    end
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if(rst) begin
            ptr <= 0;
        end
        else begin
            if(en) begin
                shadow[ptr] <= data_in;
                ptr <= next_ptr;
            end
        end
    end
    
    // 将输出寄存化，减少关键路径
    always @(posedge clk) begin
        if(rst) begin
            data_out <= {DW{1'b0}};
        end
        else begin
            data_out <= shadow[ptr];
        end
    end
endmodule