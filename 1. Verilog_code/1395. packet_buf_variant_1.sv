//SystemVerilog
module packet_buf #(parameter DW=8) (
    input wire clk, rst_n,
    input wire [DW-1:0] din,
    input wire din_valid,
    output reg [DW-1:0] dout,
    output reg pkt_valid
);
    // 使用parameter而不是reg来定义常量
    localparam [7:0] DELIMITER = 8'hFF;
    
    // 使用参数化状态定义，提高可读性
    localparam [1:0] IDLE = 2'd0,
                     DETECT = 2'd1,
                     ACTIVE = 2'd2;
    
    // 流水线寄存器和控制信号
    reg [1:0] state_stage1, next_state_stage1;
    reg [1:0] state_stage2, state_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [DW-1:0] din_stage1, din_stage2, din_stage3;
    reg is_delimiter_stage1;
    
    // 阶段1: 输入处理和状态检测
    always @(*) begin
        next_state_stage1 = state_stage1;
        case(state_stage1)
            IDLE: 
                if(din_valid && din == DELIMITER) 
                    next_state_stage1 = DETECT;
            DETECT: 
                next_state_stage1 = ACTIVE;
            ACTIVE: 
                if(!din_valid) 
                    next_state_stage1 = IDLE;
            default: 
                next_state_stage1 = IDLE;
        endcase
    end
    
    // 阶段1 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage1 <= IDLE;
            valid_stage1 <= 1'b0;
            din_stage1 <= {DW{1'b0}};
            is_delimiter_stage1 <= 1'b0;
        end
        else begin
            state_stage1 <= next_state_stage1;
            valid_stage1 <= din_valid;
            din_stage1 <= din;
            is_delimiter_stage1 <= (din == DELIMITER);
        end
    end
    
    // 阶段2 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage2 <= IDLE;
            valid_stage2 <= 1'b0;
            din_stage2 <= {DW{1'b0}};
        end
        else begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
            din_stage2 <= din_stage1;
        end
    end
    
    // 阶段3 流水线寄存器 (输出阶段)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage3 <= IDLE;
            valid_stage3 <= 1'b0;
            din_stage3 <= {DW{1'b0}};
            dout <= {DW{1'b0}};
            pkt_valid <= 1'b0;
        end
        else begin
            state_stage3 <= state_stage2;
            valid_stage3 <= valid_stage2;
            din_stage3 <= din_stage2;
            
            // 输出逻辑
            case(state_stage2)
                DETECT: begin
                    dout <= din_stage2;
                    pkt_valid <= 1'b1;
                end
                ACTIVE: begin
                    // 保持输出有效
                    pkt_valid <= 1'b1;
                end
                default: begin
                    // IDLE或其他状态
                    pkt_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule