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

    // 优化比较逻辑和数据流
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_prio <= 2'b0;
            data_out <= 32'b0;
        end else begin
            // 优先级更新逻辑
            if (prio_in > current_prio) begin
                current_prio <= prio_in[1:0];
            end else if (current_prio > 0) begin
                current_prio <= current_prio - 1'b1;
            end
            
            // 输出数据选择逻辑
            if (prio_in > current_prio) begin
                data_out <= prio_queues[prio_in[1:0]];
            end else if (current_prio > 0) begin
                data_out <= prio_queues[current_prio - 1'b1];
            end
            
            // 数据存储逻辑
            prio_queues[prio_in[1:0]] <= data_in;
        end
    end
endmodule