//SystemVerilog
module power_optimized_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_req,    // 替换原来的data_valid信号
    input wire power_save,
    output reg [7:0] crc,
    output reg data_ack     // 新增的应答信号
);
    parameter [7:0] POLY = 8'h07;
    wire gated_clk = clk & ~power_save;
    reg req_reg;            // 存储请求信号状态
    
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            crc <= 8'h00;
            data_ack <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            if (data_req && !req_reg) begin
                // 新请求到来，处理数据并产生应答
                crc <= {crc[6:0], 1'b0} ^ ((crc[7] ^ data[0]) ? POLY : 8'h00);
                data_ack <= 1'b1;
                req_reg <= 1'b1;
            end else if (!data_req && req_reg) begin
                // 请求撤销，重置应答信号
                data_ack <= 1'b0;
                req_reg <= 1'b0;
            end
        end
    end
endmodule