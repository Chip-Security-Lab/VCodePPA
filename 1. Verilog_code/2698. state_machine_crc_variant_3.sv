//SystemVerilog
module state_machine_crc(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output reg [15:0] crc_out,
    output reg crc_ready
);
    // 参数定义
    localparam [15:0] POLY = 16'h1021;
    localparam [1:0] IDLE = 2'b00, 
                    PROCESS = 2'b01, 
                    FINALIZE = 2'b10;
    
    // 寄存器声明
    reg [1:0] state;
    reg [3:0] bit_count;
    wire feedback;
    
    // 优化比较逻辑，使用单独的反馈信号
    assign feedback = crc_out[15] ^ data[bit_count];
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            crc_out <= 16'hFFFF;
            bit_count <= 4'd0;
            crc_ready <= 1'b0;
        end else begin
            if (state == IDLE) begin
                if (start) begin
                    state <= PROCESS;
                    bit_count <= 4'd0;
                    crc_ready <= 1'b0;
                end
            end else if (state == PROCESS) begin
                // 优化CRC计算逻辑
                crc_out <= {crc_out[14:0], 1'b0} ^ (feedback ? POLY : 16'h0);
                
                // 优化比较链，使用范围检查代替单点比较
                if (bit_count < 4'd7) begin
                    bit_count <= bit_count + 1'b1;
                end else begin
                    state <= FINALIZE;
                end
            end else if (state == FINALIZE) begin
                crc_ready <= 1'b1;
                state <= IDLE;
            end else begin
                state <= IDLE;
            end
        end
    end
endmodule