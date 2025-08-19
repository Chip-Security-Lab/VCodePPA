//SystemVerilog
//IEEE 1364-2005 Verilog
module serialize_reg(
    input wire clk,
    input wire reset,
    input wire [7:0] parallel_in,
    input wire req_load,     // 替换load信号为req_load
    input wire req_shift,    // 替换shift_out信号为req_shift
    output reg [7:0] p_out,
    output wire serial_out,
    output reg ack_load,     // 新增ack_load信号作为load操作的应答
    output reg ack_shift     // 新增ack_shift信号作为shift操作的应答
);
    
    // 握手状态寄存器
    reg load_done;
    reg shift_done;
    
    // 主状态更新和握手逻辑
    always @(posedge clk) begin
        if (reset) begin
            p_out <= 8'h00;
            ack_load <= 1'b0;
            ack_shift <= 1'b0;
            load_done <= 1'b0;
            shift_done <= 1'b0;
        end
        else begin
            // 加载操作握手逻辑
            if (req_load && !load_done) begin
                p_out <= parallel_in;
                ack_load <= 1'b1;
                load_done <= 1'b1;
            end
            else if (!req_load && load_done) begin
                ack_load <= 1'b0;
                load_done <= 1'b0;
            end
            
            // 移位操作握手逻辑
            if (req_shift && !shift_done) begin
                p_out <= {p_out[6:0], 1'b0};
                ack_shift <= 1'b1;
                shift_done <= 1'b1;
            end
            else if (!req_shift && shift_done) begin
                ack_shift <= 1'b0;
                shift_done <= 1'b0;
            end
        end
    end
    
    // 直接连接MSB到串行输出
    assign serial_out = p_out[7];
    
endmodule