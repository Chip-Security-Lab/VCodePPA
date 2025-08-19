//SystemVerilog
module mux_buffer (
    input wire clk,
    input wire rst_n,
    input wire [1:0] select,
    input wire [7:0] data_a, data_b, data_c, data_d,
    input wire req,          // 替代原来的valid信号作为请求信号
    output reg ack,          // 替代原来的ready信号作为应答信号
    output reg [7:0] data_out,
    output reg data_out_valid
);
    reg [7:0] buffers [0:3];
    reg data_processed;
    reg req_reg;             // 寄存请求信号
    
    // 请求-应答握手逻辑和数据写入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;           // 复位时无应答
            data_processed <= 1'b0;
            req_reg <= 1'b0;
            buffers[0] <= 8'h0;
            buffers[1] <= 8'h0;
            buffers[2] <= 8'h0;
            buffers[3] <= 8'h0;
        end else begin
            req_reg <= req;        // 寄存请求信号
            
            // 当检测到新的请求上升沿时处理数据
            if (req && !req_reg) begin
                case (select)
                    2'b00: buffers[0] <= data_a;
                    2'b01: buffers[1] <= data_b;
                    2'b10: buffers[2] <= data_c;
                    2'b11: buffers[3] <= data_d;
                endcase
                ack <= 1'b1;           // 发送应答信号
                data_processed <= 1'b1;
            end else if (ack && req_reg) begin
                ack <= 1'b0;           // 收到请求应答完成后撤销应答信号
                data_processed <= 1'b0;
            end
        end
    end
    
    // 数据输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
            data_out_valid <= 1'b0;
        end else begin
            if (data_processed) begin
                data_out <= buffers[select];
                data_out_valid <= 1'b1;
            end else begin
                data_out_valid <= 1'b0;
            end
        end
    end
endmodule