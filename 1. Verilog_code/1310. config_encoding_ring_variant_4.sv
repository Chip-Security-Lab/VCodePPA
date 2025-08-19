//SystemVerilog
module config_encoding_ring #(
    parameter ENCODING = "ONEHOT" // or "BINARY"
)(
    input wire clk, rst,
    output wire [3:0] code_out
);

    // 内部状态寄存器
    reg [3:0] code_int;
    
    // 为高扇出信号code_out添加缓冲寄存器
    reg [3:0] code_out_buf1;
    reg [3:0] code_out_buf2;
    
    // 状态更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            if (ENCODING == "ONEHOT") begin
                code_int <= 4'b0001;
            end else begin
                code_int <= 4'b0000;
            end
        end else begin
            case(ENCODING)
                "ONEHOT": begin
                    code_int <= {code_int[0], code_int[3:1]};
                end
                "BINARY": begin
                    if (code_int == 4'b1000) begin
                        code_int <= 4'b0001;
                    end else begin
                        code_int <= code_int << 1;
                    end
                end
                default: begin
                    code_int <= code_int;
                end
            endcase
        end
    end
    
    // 多级缓冲寄存器，减少扇出负载，平衡路径延迟
    always @(posedge clk) begin
        code_out_buf1 <= code_int;
        code_out_buf2 <= code_out_buf1;
    end
    
    // 将内部缓冲信号连接到输出
    assign code_out = code_out_buf2;

endmodule