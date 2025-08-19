//SystemVerilog
module source_id_ismu(
    input wire clk, rst_n,
    input wire [7:0] irq,
    input wire ack,
    output reg [2:0] src_id,
    output reg valid
);
    reg [7:0] pending;
    reg [2:0] next_src_id;
    reg next_valid;
    
    // Optimized priority encoder using leading zero count approach
    always @(*) begin
        next_valid = |pending;
        casez(pending)
            8'b1???????: next_src_id = 3'd7;
            8'b01??????: next_src_id = 3'd6;
            8'b001?????: next_src_id = 3'd5;
            8'b0001????: next_src_id = 3'd4;
            8'b00001???: next_src_id = 3'd3;
            8'b000001??: next_src_id = 3'd2;
            8'b0000001?: next_src_id = 3'd1;
            8'b00000001: next_src_id = 3'd0;
            default: begin
                next_src_id = 3'd0;
                next_valid = 1'b0;
            end
        endcase
    end
    
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            pending <= 8'h0;
            valid <= 1'b0;
            src_id <= 3'h0;
        end else begin
            // Update pending register
            if (ack)
                pending <= (pending | irq) & ~(8'h1 << src_id);
            else
                pending <= pending | irq;
            
            // Register priority encoder output
            valid <= next_valid;
            src_id <= next_src_id;
        end
    end
endmodule