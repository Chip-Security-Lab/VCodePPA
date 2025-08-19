//SystemVerilog
module crc_serial_encoder #(parameter DW=16)(
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    output reg serial_out
);
    // 状态定义
    localparam STATE_IDLE = 2'b00;
    localparam STATE_COMPUTE = 2'b01;
    localparam STATE_TRANSMIT = 2'b10;
    
    // 内部信号与寄存器
    reg [4:0] crc_reg, next_crc;
    reg [DW+4:0] shift_reg, next_shift_reg;
    reg [1:0] state, next_state;
    reg [4:0] bit_counter, next_bit_counter;
    reg compute_done, next_compute_done;
    reg next_serial_out;
    
    // 输入寄存器 - 前向重定时，将靠近输入的寄存器移到组合逻辑后
    reg [DW-1:0] data_in_reg;
    reg en_reg;
    
    // 输入捕获逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
            en_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            en_reg <= en;
        end
    end
    
    // CRC计算逻辑和下一状态逻辑 - 组合逻辑部分
    always @(*) begin
        next_crc = crc_reg;
        next_shift_reg = shift_reg;
        next_state = state;
        next_bit_counter = bit_counter;
        next_compute_done = compute_done;
        next_serial_out = serial_out;
        
        case(state)
            STATE_IDLE: begin
                if(en_reg) begin
                    next_state = STATE_COMPUTE;
                    next_shift_reg = {data_in_reg, crc_reg};
                    next_crc = crc_reg ^ data_in_reg[DW-1:DW-5];
                    next_bit_counter = DW + 5 - 1;
                    next_compute_done = 1'b0;
                end
            end
            
            STATE_COMPUTE: begin
                next_crc = crc_reg ^ shift_reg[DW+4:DW];
                next_state = STATE_TRANSMIT;
                next_compute_done = 1'b1;
            end
            
            STATE_TRANSMIT: begin
                next_serial_out = shift_reg[DW+4];
                next_shift_reg = {shift_reg[DW+3:0], 1'b0};
                
                if(bit_counter > 0)
                    next_bit_counter = bit_counter - 1'b1;
                    
                if(bit_counter == 5'd0 && compute_done) begin
                    next_state = STATE_IDLE;
                end
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end
    
    // 时序逻辑 - 优化后的寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            crc_reg <= 5'h1F;
            state <= STATE_IDLE;
            bit_counter <= 0;
            compute_done <= 1'b0;
            serial_out <= 1'b0;
        end else begin
            shift_reg <= next_shift_reg;
            crc_reg <= next_crc;
            state <= next_state;
            bit_counter <= next_bit_counter;
            compute_done <= next_compute_done;
            serial_out <= next_serial_out;
        end
    end
    
endmodule