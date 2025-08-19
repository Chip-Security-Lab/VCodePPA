//SystemVerilog
module scan_d_ff (
    input  wire clk,
    input  wire rst_n,
    input  wire scan_en,
    input  wire scan_in,
    input  wire d,
    input  wire ack,
    output reg  q,
    output wire scan_out,
    output reg  req
);
    reg data_valid;
    reg [1:0] d_value;
    
    // 使用case语句优化控制流
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            req <= 1'b0;
            data_valid <= 1'b0;
            d_value <= 2'b00;
        end else begin
            // 使用{data_valid, ack}作为case语句的控制变量
            case({data_valid, ack})
                2'b10: begin  // 数据有效但未被确认，保持当前状态
                    // 保持当前状态，等待确认信号
                end
                2'b11: begin  // 数据有效且被确认
                    q <= d_value[0];
                    req <= 1'b0;
                    data_valid <= 1'b0;
                end
                2'b00, 2'b01: begin  // 准备新数据
                    d_value <= {scan_in, d};
                    data_valid <= 1'b1;
                    req <= 1'b1;
                end
                default: begin
                    // 默认情况，不应该发生
                    // 保持当前状态
                end
            endcase
        end
    end
    
    assign scan_out = q;
endmodule