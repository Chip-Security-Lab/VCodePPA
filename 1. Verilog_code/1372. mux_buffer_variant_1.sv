//SystemVerilog
module mux_buffer (
    input wire clk,
    input wire rst_n,
    input wire [1:0] select,
    input wire [7:0] data_a, data_b, data_c, data_d,
    input wire data_valid,
    output reg data_ready,
    output reg [7:0] data_out,
    output reg data_out_valid
);
    reg [7:0] buffers [0:3];
    reg write_done;
    
    // 合并两个always块为一个，因为它们具有相同的触发条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位逻辑
            buffers[0] <= 8'h0;
            buffers[1] <= 8'h0;
            buffers[2] <= 8'h0;
            buffers[3] <= 8'h0;
            data_ready <= 1'b1;
            write_done <= 1'b0;
            data_out <= 8'h0;
            data_out_valid <= 1'b0;
        end else begin
            // 握手和缓冲区写入逻辑
            data_ready <= 1'b1;
            
            if (data_valid && data_ready) begin
                case (select)
                    2'b00: buffers[0] <= data_a;
                    2'b01: buffers[1] <= data_b;
                    2'b10: buffers[2] <= data_c;
                    2'b11: buffers[3] <= data_d;
                endcase
                write_done <= 1'b1;
                data_ready <= 1'b0;
            end else if (write_done) begin
                write_done <= 1'b0;
                data_ready <= 1'b1;
            end
            
            // 数据输出逻辑
            if (write_done) begin
                data_out <= buffers[select];
                data_out_valid <= 1'b1;
            end else begin
                data_out_valid <= 1'b0;
            end
        end
    end
endmodule