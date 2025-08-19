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
    localparam IDLE=2'b00, TOKEN=2'b01, DATA=2'b10, STATUS=2'b11;
    reg [1:0] NextState;
    
    always @(*) begin
        NextState = CurrentState;
        case(CurrentState)
            IDLE:   if(TOKEN_Received) NextState = TOKEN;
                    else if(SOF_Received) NextState = IDLE;
            TOKEN:  if(DATA_Received) NextState = DATA;
            DATA:   NextState = STATUS;
            STATUS: NextState = IDLE;
            default: NextState = IDLE;
        endcase
    end
    
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            CurrentState <= IDLE;
            SendACK <= 1'b0;
            SendNAK <= 1'b0;
            SendDATA <= 1'b0;
        end else begin
            CurrentState <= NextState;
            SendACK <= (CurrentState == DATA && NextState == STATUS);
            SendNAK <= 1'b0; // Simplified for brevity
            SendDATA <= (CurrentState == TOKEN && NextState == DATA);
        end
    end
endmodule