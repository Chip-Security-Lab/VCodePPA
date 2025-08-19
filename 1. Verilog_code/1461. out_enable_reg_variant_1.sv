//SystemVerilog
module out_enable_reg(
    input clk, rst,
    input [15:0] data_in,
    input req,
    output reg ack,
    output [15:0] data_out
);
    reg [15:0] stored_data;
    reg data_valid;

    // 状态控制和数据处理分离为两个always块，改善时序和资源利用
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ack <= 1'b0;
        end
        else if (req ^ ack) begin  // 使用XOR操作简化状态判断
            ack <= req;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_data <= 16'h0;
            data_valid <= 1'b0;
        end
        else if (req && !ack) begin
            stored_data <= data_in;
            data_valid <= 1'b1;
        end
    end
    
    // 三态输出逻辑保持不变
    assign data_out = data_valid ? stored_data : 16'hZ;
endmodule