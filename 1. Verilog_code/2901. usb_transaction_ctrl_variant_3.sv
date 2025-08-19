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
    // Local parameters
    localparam IDLE=2'b00, TOKEN=2'b01, DATA=2'b10, STATUS=2'b11;
    
    // Create clock buffer tree for high fanout clock signal
    wire clk_buf1, clk_buf2, clk_buf3;
    assign clk_buf1 = Clock;
    assign clk_buf2 = Clock;
    assign clk_buf3 = Clock;
    
    // State variables
    reg [1:0] NextState_stage1;         // 第一级流水线计算下一状态
    reg [1:0] NextState_stage2;         // 第二级流水线确认下一状态
    
    // Buffer registers for NextState_stage1 (high fanout)
    reg [1:0] NextState_stage1_buf1;
    reg [1:0] NextState_stage1_buf2;
    
    // Buffer registers for CurrentState (high fanout)
    reg [1:0] CurrentState_buf1;
    reg [1:0] CurrentState_buf2;
    reg [1:0] CurrentState_buf3;
    
    // Buffer for IDLE constant (high fanout)
    reg [1:0] IDLE_buf1, IDLE_buf2;
    
    // Input capture registers
    reg TOKEN_Received_reg;
    reg DATA_Received_reg;
    reg SOF_Received_reg;
    
    // Buffer for b0 signal (represented by TOKEN_Received)
    reg TOKEN_Received_buf1, TOKEN_Received_buf2;
    
    // Output signals intermediate computation
    reg SendACK_stage1;
    reg SendDATA_stage1;
    
    // Update buffer registers for high fanout signals
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            CurrentState_buf1 <= IDLE;
            CurrentState_buf2 <= IDLE;
            CurrentState_buf3 <= IDLE;
            NextState_stage1_buf1 <= IDLE;
            NextState_stage1_buf2 <= IDLE;
            IDLE_buf1 <= IDLE;
            IDLE_buf2 <= IDLE;
            TOKEN_Received_buf1 <= 1'b0;
            TOKEN_Received_buf2 <= 1'b0;
        end else begin
            CurrentState_buf1 <= CurrentState;
            CurrentState_buf2 <= CurrentState;
            CurrentState_buf3 <= CurrentState;
            NextState_stage1_buf1 <= NextState_stage1;
            NextState_stage1_buf2 <= NextState_stage1;
            IDLE_buf1 <= IDLE;
            IDLE_buf2 <= IDLE;
            TOKEN_Received_buf1 <= TOKEN_Received;
            TOKEN_Received_buf2 <= TOKEN_Received;
        end
    end
    
    // First pipeline stage: capture inputs and perform initial computation
    always @(posedge clk_buf1 or negedge Reset_n) begin
        if(!Reset_n) begin
            TOKEN_Received_reg <= 1'b0;
            DATA_Received_reg <= 1'b0;
            SOF_Received_reg <= 1'b0;
            NextState_stage1 <= IDLE;
        end else begin
            TOKEN_Received_reg <= TOKEN_Received_buf1;
            DATA_Received_reg <= DATA_Received;
            SOF_Received_reg <= SOF_Received;
            
            // Initial computation of next state
            case(CurrentState_buf1)
                IDLE_buf1: if(TOKEN_Received_buf1) 
                            NextState_stage1 <= TOKEN;
                        else if(SOF_Received)
                            NextState_stage1 <= IDLE_buf1;
                        else
                            NextState_stage1 <= CurrentState_buf1;
                TOKEN:  if(DATA_Received)
                            NextState_stage1 <= DATA;
                        else
                            NextState_stage1 <= CurrentState_buf1;
                DATA:   NextState_stage1 <= STATUS;
                STATUS: NextState_stage1 <= IDLE_buf1;
                default: NextState_stage1 <= IDLE_buf1;
            endcase
        end
    end
    
    // Second pipeline stage: complete state transition computation and prepare output control signals
    always @(posedge clk_buf2 or negedge Reset_n) begin
        if(!Reset_n) begin
            NextState_stage2 <= IDLE;
            SendACK_stage1 <= 1'b0;
            SendDATA_stage1 <= 1'b0;
        end else begin
            NextState_stage2 <= NextState_stage1_buf1;
            
            // Prepare intermediate results for output control signals
            SendACK_stage1 <= (CurrentState_buf2 == DATA && NextState_stage1_buf1 == STATUS);
            SendDATA_stage1 <= (CurrentState_buf2 == TOKEN && NextState_stage1_buf1 == DATA);
        end
    end
    
    // Third pipeline stage: update current state and outputs
    always @(posedge clk_buf3 or negedge Reset_n) begin
        if(!Reset_n) begin
            CurrentState <= IDLE;
            SendACK <= 1'b0;
            SendNAK <= 1'b0;
            SendDATA <= 1'b0;
        end else begin
            CurrentState <= NextState_stage2;
            SendACK <= SendACK_stage1;
            SendNAK <= 1'b0; // Simplified for brevity
            SendDATA <= SendDATA_stage1;
        end
    end
endmodule