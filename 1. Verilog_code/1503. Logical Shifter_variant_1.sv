//SystemVerilog
// IEEE 1364-2005 Verilog标准
module logical_shifter #(parameter W = 16) (
    input wire clock, reset_n, load, shift,
    input wire [W-1:0] data,
    output wire [W-1:0] q_out
);
    reg [W-1:0] q_reg;
    
    // 优化控制逻辑，使用case语句提高清晰度和效率
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            q_reg <= {W{1'b0}};
        end else begin
            case ({load, shift})
                2'b10:   q_reg <= data;                  // 加载操作
                2'b01:   q_reg <= {1'b0, q_reg[W-1:1]};  // 右移操作
                default: q_reg <= q_reg;                 // 保持当前值
            endcase
        end
    end
    
    // 直接赋值输出
    assign q_out = q_reg;
endmodule