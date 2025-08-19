//SystemVerilog
module lin_codec (
    input clk, break_detect,
    input [7:0] pid,
    output reg tx
);
    reg [12:0] shift_reg;
    reg break_detect_reg;
    reg [7:0] pid_reg;
    
    always @(posedge clk) begin
        // 寄存器前移：先寄存输入信号
        break_detect_reg <= break_detect;
        pid_reg <= pid;
        
        // 重新安排组合逻辑和寄存器的位置
        shift_reg <= break_detect_reg ? {pid_reg, 4'h0} : {shift_reg[11:0], 1'b1};
        tx <= break_detect_reg ? 1'b0 : (break_detect ? 1'b0 : shift_reg[12]);
    end
endmodule