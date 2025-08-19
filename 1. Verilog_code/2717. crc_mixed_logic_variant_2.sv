//SystemVerilog
module crc_mixed_logic (
    input  wire        clk,
    input  wire        req,         // 替代原来的valid信号
    input  wire [15:0] data_in,
    output reg         ack,         // 替代原来的ready信号
    output reg  [7:0]  crc
);
    // 内部状态定义
    localparam IDLE = 2'b00;
    localparam PROC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 第一级：数据预处理阶段
    reg [15:0] data_in_reg;
    reg        data_valid;
    
    // 第二级：XOR运算阶段
    reg [7:0]  xor_result;
    wire [7:0] comb_part;
    
    // 第三级：CRC计算阶段  
    wire [7:0] crc_next;
    
    // 数据流路径定义
    assign comb_part = data_in_reg[15:8] ^ data_in_reg[7:0];
    assign crc_next = {comb_part[6:0], comb_part[7]} ^ 8'h07;
    
    // 状态机：控制req-ack握手过程
    always @(posedge clk) begin
        state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (req) next_state = PROC;
            PROC: next_state = DONE;
            DONE: if (!req) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理和握手控制
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                ack <= 1'b0;
                if (req) begin
                    data_in_reg <= data_in;
                    data_valid <= 1'b1;
                end else begin
                    data_valid <= 1'b0;
                end
            end
            
            PROC: begin
                ack <= 1'b1;
                xor_result <= comb_part;
                data_valid <= 1'b0;
            end
            
            DONE: begin
                crc <= crc_next;
                if (!req) begin
                    ack <= 1'b0;
                end
            end
            
            default: begin
                ack <= 1'b0;
                data_valid <= 1'b0;
            end
        endcase
    end
endmodule