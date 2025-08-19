//SystemVerilog
module usb_nrzi_encoder(
    input wire clk,
    input wire reset,
    input wire data_in,
    input wire valid_in,
    output reg data_out,
    output reg valid_out
);
    // 将寄存器移到组合逻辑之后
    reg data_in_r;
    reg valid_in_r;
    reg last_bit;
    
    // 寄存器重定时 - 第一级寄存器捕获输入信号
    always @(posedge clk) begin
        if (reset) begin
            data_in_r <= 1'b0;
            valid_in_r <= 1'b0;
        end else begin
            data_in_r <= data_in;
            valid_in_r <= valid_in;
        end
    end
    
    // 输出逻辑与状态维护 - 使用case语句替代if-else级联
    always @(posedge clk) begin
        case (1'b1) // 优先级编码的case语句
            reset: begin
                data_out <= 1'b1;
                last_bit <= 1'b1;
                valid_out <= 1'b0;
            end
            
            valid_in_r: begin
                valid_out <= 1'b1;
                case (data_in_r)
                    1'b0: begin
                        data_out <= ~last_bit;
                        last_bit <= ~last_bit;
                    end
                    
                    1'b1: begin
                        data_out <= last_bit;
                        // last_bit保持不变
                    end
                endcase
            end
            
            default: begin
                valid_out <= 1'b0;
                // 其他信号保持不变
            end
        endcase
    end
endmodule