//SystemVerilog
module usb_transaction_ctrl(
    input wire Clock,
    input wire Reset_n,
    input wire SOF_Received,
    input wire TOKEN_Received,
    input wire DATA_Received,
    input wire ACK_Received, 
    input wire NAK_Received,
    output reg SendACK,
    output reg SendNAK,
    output reg SendDATA,
    output reg [1:0] CurrentState
);
    // 状态编码
    localparam IDLE=2'b00, TOKEN=2'b01, DATA=2'b10, STATUS=2'b11;
    
    // 流水线寄存器 - 第1级：输入捕获
    reg SOF_Received_stage1, TOKEN_Received_stage1, DATA_Received_stage1;
    reg ACK_Received_stage1, NAK_Received_stage1;
    
    // 流水线寄存器 - 第2级：状态处理
    reg [1:0] CurrentState_stage2;
    reg valid_stage2;
    
    // 流水线寄存器 - 第3级：输出生成
    reg [1:0] CurrentState_stage3;
    reg token_to_data_transition_stage3;
    reg data_to_status_transition_stage3;
    reg valid_stage3;
    
    // 流水线控制信号
    reg valid_stage1;
    
    // 流水线级别1：输入捕获
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            SOF_Received_stage1 <= 1'b0;
            TOKEN_Received_stage1 <= 1'b0;
            DATA_Received_stage1 <= 1'b0;
            ACK_Received_stage1 <= 1'b0;
            NAK_Received_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            SOF_Received_stage1 <= SOF_Received;
            TOKEN_Received_stage1 <= TOKEN_Received;
            DATA_Received_stage1 <= DATA_Received;
            ACK_Received_stage1 <= ACK_Received;
            NAK_Received_stage1 <= NAK_Received;
            valid_stage1 <= 1'b1; // 设置为有效，第一级始终有效
        end
    end
    
    // 流水线级别2：状态处理
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            CurrentState_stage2 <= IDLE;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if(valid_stage1) begin
                case(CurrentState)
                    IDLE:   if(TOKEN_Received_stage1) 
                                CurrentState_stage2 <= TOKEN;
                            else if(SOF_Received_stage1) 
                                CurrentState_stage2 <= IDLE;
                            else
                                CurrentState_stage2 <= IDLE;
                    TOKEN:  if(DATA_Received_stage1) 
                                CurrentState_stage2 <= DATA;
                            else
                                CurrentState_stage2 <= TOKEN;
                    DATA:   CurrentState_stage2 <= STATUS;
                    STATUS: CurrentState_stage2 <= IDLE;
                    default: CurrentState_stage2 <= IDLE;
                endcase
            end
        end
    end
    
    // 流水线级别3：转换条件计算和输出准备
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            CurrentState_stage3 <= IDLE;
            token_to_data_transition_stage3 <= 1'b0;
            data_to_status_transition_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            CurrentState_stage3 <= CurrentState_stage2;
            valid_stage3 <= valid_stage2;
            
            if(valid_stage2) begin
                token_to_data_transition_stage3 <= (CurrentState_stage2 == TOKEN && DATA_Received_stage1);
                data_to_status_transition_stage3 <= (CurrentState_stage2 == DATA);
            end else begin
                token_to_data_transition_stage3 <= 1'b0;
                data_to_status_transition_stage3 <= 1'b0;
            end
        end
    end
    
    // 流水线级别4：输出生成
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            SendACK <= 1'b0;
            SendNAK <= 1'b0;
            SendDATA <= 1'b0;
            CurrentState <= IDLE;
        end else begin
            CurrentState <= CurrentState_stage3;
            
            if(valid_stage3) begin
                SendACK <= data_to_status_transition_stage3;
                SendNAK <= 1'b0; // 简化，原逻辑保持
                SendDATA <= token_to_data_transition_stage3;
            end else begin
                SendACK <= 1'b0;
                SendNAK <= 1'b0;
                SendDATA <= 1'b0;
            end
        end
    end
    
endmodule