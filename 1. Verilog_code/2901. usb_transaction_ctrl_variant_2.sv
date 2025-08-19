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
    // State encoding
    localparam IDLE=2'b00, TOKEN=2'b01, DATA=2'b10, STATUS=2'b11;
    
    // Pipeline stage registers
    reg [1:0] stage1_state, stage2_state, stage3_state;
    reg stage1_valid, stage2_valid, stage3_valid;
    reg stage1_token_received, stage2_data_received;
    
    // Pipeline control signals
    reg pipe_enable;
    wire stage1_ready, stage2_ready, stage3_ready;
    
    // Ready-valid handshaking for pipeline stages
    assign stage3_ready = 1'b1; // Output stage is always ready
    assign stage2_ready = !stage3_valid || stage3_ready;
    assign stage1_ready = !stage2_valid || stage2_ready;
    
    // Pipeline enable logic
    always @(*) begin
        pipe_enable = 1'b1; // Default: pipeline runs freely
    end
    
    // Stage 1: Input Capture and Initial State Determination
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            stage1_state <= IDLE;
            stage1_valid <= 1'b0;
            stage1_token_received <= 1'b0;
        end else if(stage1_ready) begin
            case(CurrentState)
                IDLE: begin
                    stage1_state <= TOKEN_Received ? TOKEN : IDLE;
                    stage1_valid <= TOKEN_Received;
                    stage1_token_received <= TOKEN_Received;
                end
                TOKEN: begin
                    stage1_state <= DATA_Received ? DATA : TOKEN;
                    stage1_valid <= DATA_Received;
                    stage1_token_received <= 1'b1;
                end
                DATA: begin
                    stage1_state <= STATUS;
                    stage1_valid <= 1'b1;
                    stage1_token_received <= 1'b1;
                end
                STATUS: begin
                    stage1_state <= IDLE;
                    stage1_valid <= 1'b1;
                    stage1_token_received <= 1'b0;
                end
                default: begin
                    stage1_state <= IDLE;
                    stage1_valid <= 1'b0;
                    stage1_token_received <= 1'b0;
                end
            endcase
        end
    end
    
    // Stage 2: Intermediate State Processing
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            stage2_state <= IDLE;
            stage2_valid <= 1'b0;
            stage2_data_received <= 1'b0;
        end else if(stage2_ready) begin
            if(stage1_valid) begin
                stage2_state <= stage1_state;
                stage2_valid <= stage1_valid;
                stage2_data_received <= (stage1_state == DATA);
            end else begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // Stage 3: Output Generation
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            stage3_state <= IDLE;
            stage3_valid <= 1'b0;
            SendACK <= 1'b0;
            SendNAK <= 1'b0;
            SendDATA <= 1'b0;
        end else if(stage3_ready) begin
            if(stage2_valid) begin
                stage3_state <= stage2_state;
                stage3_valid <= stage2_valid;
                
                // Reset all outputs by default
                SendACK <= 1'b0;
                SendNAK <= 1'b0;
                SendDATA <= 1'b0;
                
                // Set specific outputs based on state
                case(stage2_state)
                    DATA:   SendDATA <= 1'b1;
                    STATUS: SendACK <= 1'b1;
                    default: ; // No action needed
                endcase
            end else begin
                stage3_valid <= 1'b0;
                SendACK <= 1'b0;
                SendNAK <= 1'b0;
                SendDATA <= 1'b0;
            end
        end
    end
    
    // Update current state for output
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            CurrentState <= IDLE;
        end else begin
            CurrentState <= stage3_state;
        end
    end
    
endmodule