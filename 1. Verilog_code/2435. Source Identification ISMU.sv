module source_id_ismu(
    input wire clk, rst_n,
    input wire [7:0] irq,
    input wire ack,
    output reg [2:0] src_id,
    output reg valid
);
    reg [7:0] pending;
    
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            pending <= 8'h0;
            valid <= 1'b0;
            src_id <= 3'h0;
        end else begin
            pending <= pending | irq;
            
            if (ack)
                pending[src_id] <= 1'b0;
                
            valid <= |pending;
            casez (pending)
                8'b???????1: src_id <= 3'd0;
                8'b??????10: src_id <= 3'd1;
                8'b?????100: src_id <= 3'd2;
                8'b????1000: src_id <= 3'd3;
                8'b???10000: src_id <= 3'd4;
                8'b??100000: src_id <= 3'd5;
                8'b?1000000: src_id <= 3'd6;
                8'b10000000: src_id <= 3'd7;
                default: valid <= 1'b0;
            endcase
        end
    end
endmodule