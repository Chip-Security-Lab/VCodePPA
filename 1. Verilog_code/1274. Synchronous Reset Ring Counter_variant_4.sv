//SystemVerilog
module sync_reset_ring_counter(
    input wire clock,
    input wire reset, // Active-high reset
    output reg [3:0] out
);
    // 增加流水线寄存器
    reg [3:0] stage1_data;
    reg [3:0] stage2_data;
    
    // 合并所有posedge clock触发的always块
    always @(posedge clock) begin
        if (reset)
            stage1_data <= 4'b0001; // Initial state
        else
            stage1_data <= {out[2:0], out[3]}; // Rotate
            
        stage2_data <= stage1_data;
        out <= stage2_data;
    end
endmodule