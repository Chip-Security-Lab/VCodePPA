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
    reg [2:0] encoded_idx_p1, encoded_idx_p2;
    reg [7:0] req_reg_p1;
    
    // Split priority encoder into two pipeline stages
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            encoded_idx_p1 <= 3'd0;
            encoded_idx_p2 <= 3'd0;
            req_reg_p1 <= 8'h00;
        end else begin
            // First pipeline stage: encode high nibble
            encoded_idx_p1 <= req_reg[7] ? 3'd7 :
                            req_reg[6] ? 3'd6 :
                            req_reg[5] ? 3'd5 :
                            req_reg[4] ? 3'd4 : 3'd0;
            
            // Second pipeline stage: encode low nibble
            encoded_idx_p2 <= req_reg[3] ? 3'd3 :
                            req_reg[2] ? 3'd2 :
                            req_reg[1] ? 3'd1 : 3'd0;
            
            req_reg_p1 <= req_reg;
        end
    end
    
    // Final selection logic
    wire [2:0] encoded_idx = (req_reg_p1[7:4] != 4'h0) ? encoded_idx_p1 : encoded_idx_p2;
    
    always @(posedge clk or negedge rst)
        if (!rst) begin
            state <= IDLE;
            req_reg <= 8'h00;
            grant_idx <= 3'd0;
            valid <= 1'b0;
            error <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    error <= 1'b0;
                    if (enable) req_reg <= requests;
                end
                CHECK: begin
                    if (req_reg == 8'h00) error <= 1'b1;
                end
                ENCODE: begin
                    valid <= 1'b1;
                    grant_idx <= encoded_idx;
                end
                ERROR_STATE: begin
                    error <= 1'b1;
                    valid <= 1'b0;
                end
            endcase
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