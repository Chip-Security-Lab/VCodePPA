//SystemVerilog
module MIPI_CommandParser #(
    parameter CMD_TABLE_SIZE = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] cmd_byte,
    input wire cmd_valid,
    output reg [15:0] param_reg,
    output reg cmd_ready
);

    // 命令表定义
    reg [7:0] cmd_opcodes [0:CMD_TABLE_SIZE-1];
    reg [3:0] cmd_param_lens [0:CMD_TABLE_SIZE-1];
    
    // 初始化命令表
    initial begin
        cmd_opcodes[0] = 8'h01; cmd_param_lens[0] = 4'd2;
        cmd_opcodes[1] = 8'h02; cmd_param_lens[1] = 4'd1;
        cmd_opcodes[2] = 8'h03; cmd_param_lens[2] = 4'd3;
        cmd_opcodes[3] = 8'h04; cmd_param_lens[3] = 4'd0;
    end
    
    reg [2:0] state;
    reg [3:0] param_counter;
    reg [3:0] current_cmd_index;
    reg cmd_found;
    
    // 缓冲寄存器定义
    reg [7:0] cmd_byte_buf;
    reg [7:0] cmd_opcodes_buf [0:CMD_TABLE_SIZE-1];
    reg [3:0] cmd_param_lens_buf [0:CMD_TABLE_SIZE-1];
    reg [3:0] param_counter_buf;
    
    // 并行前缀减法器相关信号
    wire [3:0] param_counter_next;
    wire [3:0] param_counter_minus_1;
    wire [3:0] param_counter_minus_2;
    wire [3:0] param_counter_minus_4;
    wire [3:0] param_counter_minus_8;
    
    // 并行前缀减法器实现
    assign param_counter_minus_1 = param_counter_buf - 4'b0001;
    assign param_counter_minus_2 = param_counter_buf - 4'b0010;
    assign param_counter_minus_4 = param_counter_buf - 4'b0100;
    assign param_counter_minus_8 = param_counter_buf - 4'b1000;
    
    // 并行前缀减法器选择逻辑
    assign param_counter_next = (param_counter_buf > 4'b1000) ? param_counter_minus_8 :
                               (param_counter_buf > 4'b0100) ? param_counter_minus_4 :
                               (param_counter_buf > 4'b0010) ? param_counter_minus_2 :
                               param_counter_minus_1;
    
    // 缓冲寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_byte_buf <= 0;
            for (int i = 0; i < CMD_TABLE_SIZE; i = i + 1) begin
                cmd_opcodes_buf[i] <= 0;
                cmd_param_lens_buf[i] <= 0;
            end
            param_counter_buf <= 0;
        end else begin
            cmd_byte_buf <= cmd_byte;
            for (int i = 0; i < CMD_TABLE_SIZE; i = i + 1) begin
                cmd_opcodes_buf[i] <= cmd_opcodes[i];
                cmd_param_lens_buf[i] <= cmd_param_lens[i];
            end
            param_counter_buf <= param_counter;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            param_reg <= 0;
            cmd_ready <= 1;
            param_counter <= 0;
            current_cmd_index <= 0;
            cmd_found <= 0;
        end else begin
            case(state)
                0: begin
                    if (cmd_valid && cmd_ready) begin
                        cmd_found <= 0;
                        current_cmd_index <= 0;
                        
                        if (cmd_byte_buf == cmd_opcodes_buf[0]) begin
                            param_counter <= cmd_param_lens_buf[0];
                            current_cmd_index <= 0;
                            cmd_found <= 1;
                        end else if (cmd_byte_buf == cmd_opcodes_buf[1]) begin
                            param_counter <= cmd_param_lens_buf[1];
                            current_cmd_index <= 1;
                            cmd_found <= 1;
                        end else if (cmd_byte_buf == cmd_opcodes_buf[2]) begin
                            param_counter <= cmd_param_lens_buf[2];
                            current_cmd_index <= 2;
                            cmd_found <= 1;
                        end
                        
                        if (cmd_found) begin
                            state <= 1;
                            cmd_ready <= 0;
                        end
                    end
                end
                
                1: begin
                    if (cmd_valid) begin
                        param_reg <= {param_reg[7:0], cmd_byte_buf};
                        if (param_counter_buf <= 1) begin
                            state <= 2;
                            cmd_ready <= 1;
                        end else begin
                            param_counter <= param_counter_next;
                        end
                    end
                end
                
                2: begin
                    state <= 0;
                end
                
                default: begin
                    state <= 0;
                end
            endcase
        end
    end
endmodule