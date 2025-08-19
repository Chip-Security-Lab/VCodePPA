//SystemVerilog
module dram_ctrl_basic #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,
    input cmd_valid,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg ready
);

    localparam IDLE = 3'd0,
               ACTIVE = 3'd1,
               READ = 3'd2,
               WRITE = 3'd3,
               PRECHARGE = 3'd4;
    
    reg [2:0] current_state;
    reg [3:0] timer;
    
    // 优化的并行前缀减法器
    wire [3:0] timer_next;
    wire [3:0] prop;
    wire [3:0] gen;
    wire [3:0] carry;
    
    // 并行计算传播和生成信号
    assign prop = ~timer;
    assign gen = timer;
    
    // 优化的并行前缀进位计算
    wire [1:0] carry_01, carry_23;
    wire carry_012;
    
    assign carry_01 = gen[1:0] | (prop[1:0] & {1'b0, gen[0]});
    assign carry_23 = gen[3:2] | (prop[3:2] & {1'b0, gen[2]});
    assign carry_012 = carry_01[1] | (prop[2] & carry_01[0]);
    
    assign carry = {carry_23[1] | (prop[3] & carry_012),
                   carry_012,
                   carry_01[1],
                   gen[0]};
    
    // 并行计算减法结果
    assign timer_next = prop ^ {carry[2:0], 1'b1};
    
    // 状态机优化
    wire timer_zero = ~|timer;
    wire state_idle = (current_state == IDLE);
    wire state_active = (current_state == ACTIVE);
    wire state_read = (current_state == READ);
    wire state_precharge = (current_state == PRECHARGE);
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            current_state <= IDLE;
            timer <= 0;
            ready <= 1;
            data_out <= 0;
        end else begin
            case(1'b1)
                state_idle: if(cmd_valid) begin
                    current_state <= ACTIVE;
                    timer <= 4'd3;
                end
                state_active: if(timer_zero) current_state <= READ;
                             else timer <= timer_next;
                state_read: begin
                    data_out <= {DATA_WIDTH{1'b1}};
                    current_state <= PRECHARGE;
                    timer <= 4'd2;
                end
                state_precharge: if(timer_zero) current_state <= IDLE;
                                else timer <= timer_next;
                default: current_state <= IDLE;
            endcase
            ready <= state_idle;
        end
    end
endmodule