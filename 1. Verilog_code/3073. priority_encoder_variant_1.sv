//SystemVerilog
module priority_encoder(
    input wire clk, rst,
    input wire [7:0] requests,
    input wire enable,
    output reg [2:0] grant_idx,
    output reg valid, error
);
    localparam IDLE=0, CHECK=1, ENCODE=2, ERROR_STATE=3;
    reg [1:0] state, next;
    reg [7:0] req_reg;
    reg [7:0] req_reg_pipe;
    reg [2:0] grant_idx_pipe;
    reg valid_pipe, error_pipe;
    
    always @(posedge clk or negedge rst)
        if (!rst) begin
            state <= IDLE;
            req_reg <= 8'h00;
            req_reg_pipe <= 8'h00;
            grant_idx <= 3'd0;
            grant_idx_pipe <= 3'd0;
            valid <= 1'b0;
            valid_pipe <= 1'b0;
            error <= 1'b0;
            error_pipe <= 1'b0;
        end else begin
            state <= next;
            req_reg_pipe <= req_reg;
            
            case (state)
                IDLE: begin
                    valid_pipe <= 1'b0;
                    error_pipe <= 1'b0;
                    if (enable) req_reg <= requests;
                end
                CHECK: begin
                    if (req_reg == 8'h00) error_pipe <= 1'b1;
                end
                ENCODE: begin
                    valid_pipe <= 1'b1;
                    if (req_reg[7]) grant_idx_pipe <= 3'd7;
                    else if (req_reg[6]) grant_idx_pipe <= 3'd6;
                    else if (req_reg[5]) grant_idx_pipe <= 3'd5;
                    else if (req_reg[4]) grant_idx_pipe <= 3'd4;
                    else if (req_reg[3]) grant_idx_pipe <= 3'd3;
                    else if (req_reg[2]) grant_idx_pipe <= 3'd2;
                    else if (req_reg[1]) grant_idx_pipe <= 3'd1;
                    else grant_idx_pipe <= 3'd0;
                end
                ERROR_STATE: begin
                    error_pipe <= 1'b1;
                    valid_pipe <= 1'b0;
                end
            endcase
            
            grant_idx <= grant_idx_pipe;
            valid <= valid_pipe;
            error <= error_pipe;
        end
    
    always @(*)
        case (state)
            IDLE: next = enable ? CHECK : IDLE;
            CHECK: next = (req_reg == 8'h00) ? ERROR_STATE : ENCODE;
            ENCODE: next = IDLE;
            ERROR_STATE: next = IDLE;
            default: next = IDLE;
        endcase
endmodule