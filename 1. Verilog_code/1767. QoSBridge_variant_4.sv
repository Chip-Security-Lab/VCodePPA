//SystemVerilog
module QoSBridge #(
    parameter PRIO_LEVELS=4
)(
    input clk, rst_n,
    input [3:0] prio_in,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] prio_queues [0:PRIO_LEVELS-1];
    reg [1:0] current_prio;
    
    // 查找表辅助减法器实现
    reg [1:0] sub_result;
    reg [3:0] lut_addr;
    reg [1:0] lut_sub_result [0:3]; // 查找表存储预计算的减法结果
    
    // 初始化查找表
    initial begin
        lut_sub_result[0] = 2'd0; // 0-1=0(限制为0)
        lut_sub_result[1] = 2'd0; // 1-1=0
        lut_sub_result[2] = 2'd1; // 2-1=1
        lut_sub_result[3] = 2'd2; // 3-1=2
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            current_prio <= 2'd0;
            data_out <= 32'd0;
        end else begin
            if (prio_in > current_prio) begin
                current_prio <= prio_in;
                data_out <= prio_queues[prio_in];
            end else if (current_prio > 0) begin
                // 使用查找表进行减法运算
                lut_addr <= {2'b00, current_prio};
                sub_result <= lut_sub_result[current_prio];
                current_prio <= sub_result;
                data_out <= prio_queues[sub_result];
            end
            prio_queues[prio_in] <= data_in;
        end
    end
endmodule