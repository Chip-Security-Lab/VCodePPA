//SystemVerilog
module crc8_serial (
    input clk, rst_n,
    input valid,          // 数据有效信号(原en信号)
    input [7:0] data_in,  // 数据输入
    output reg [7:0] crc_out, // CRC输出
    output ready          // 数据接收就绪信号(新增)
);

parameter POLY = 8'h07;

// 内部状态和控制信号
reg processing;
reg [1:0] state;
localparam IDLE = 2'b00;
localparam COMPUTE = 2'b01;
localparam DONE = 2'b10;

// 就绪信号生成
assign ready = !processing;

// 状态机实现
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_out <= 8'hFF;
        processing <= 1'b0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                if (valid && ready) begin
                    processing <= 1'b1;
                    state <= COMPUTE;
                    crc_out <= {crc_out[6:0], 1'b0} ^ 
                              (crc_out[7] ? (POLY ^ {data_in, 1'b0}) : {data_in, 1'b0});
                end
            end
            
            COMPUTE: begin
                processing <= 1'b0;
                state <= DONE;
            end
            
            DONE: begin
                state <= IDLE;
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule