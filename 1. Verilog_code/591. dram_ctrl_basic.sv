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
    // 使用localparam定义状态，而不是enum
    localparam IDLE = 3'd0,
               ACTIVE = 3'd1,
               READ = 3'd2,
               WRITE = 3'd3,
               PRECHARGE = 3'd4;
    
    reg [2:0] current_state;
    
    // 时序计数器
    reg [3:0] timer;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            current_state <= IDLE;
            timer <= 0;
            ready <= 1;
            data_out <= 0;
        end else begin
            case(current_state)
                IDLE: if(cmd_valid) begin
                    // 进入激活状态
                    current_state <= ACTIVE;
                    timer <= 4'd3;  // tRCD=3
                end
                ACTIVE: if(timer == 0) current_state <= READ;
                        else timer <= timer - 1;
                READ: begin
                    data_out <= {DATA_WIDTH{1'b1}}; // 示例数据
                    current_state <= PRECHARGE;
                    timer <= 4'd2; // tRP=2
                end
                PRECHARGE: if(timer == 0) current_state <= IDLE;
                           else timer <= timer - 1;
                default: current_state <= IDLE;  // 添加默认状态
            endcase
            ready <= (current_state == IDLE);
        end
    end
endmodule