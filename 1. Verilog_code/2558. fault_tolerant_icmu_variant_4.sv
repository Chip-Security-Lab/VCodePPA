//SystemVerilog
module fault_tolerant_icmu (
    input clk_a, clk_b, reset_n,
    input [7:0] irq_a, irq_b,
    output reg [2:0] int_id_a, int_id_b,
    output reg int_valid_a, int_valid_b,
    output reg [1:0] error_status,
    input err_clear
);

    reg [7:0] pending_a, pending_b;
    reg [7:0] masked_a, masked_b;
    reg [7:0] mask = 8'hFF;
    reg error_detected;
    reg [2:0] next_id_a, next_id_b;
    reg next_valid_a, next_valid_b;
    reg [1:0] next_error_status;
    reg [7:0] next_pending_a, next_pending_b;
    reg [7:0] next_masked_a, next_masked_b;
    
    // Clock domain A
    always @(posedge clk_a or negedge reset_n) begin
        if (!reset_n) begin
            pending_a <= 8'h00;
            masked_a <= 8'h00;
            int_id_a <= 3'd0;
            int_valid_a <= 1'b0;
            error_status[0] <= 1'b0;
        end else begin
            next_pending_a = pending_a | irq_a;
            next_masked_a = next_pending_a & mask;
            next_id_a = encode_id(next_masked_a);
            
            // Optimized state update logic
            next_valid_a = (|next_masked_a) ? !int_valid_a : int_valid_a;
            if (!int_valid_a && |next_masked_a) begin
                next_pending_a[next_id_a] = 1'b0;
            end
            
            // Optimized error detection
            next_error_status[0] = (int_valid_a && int_valid_b && (int_id_a != int_id_b)) ? 1'b1 : 
                                 (err_clear ? 1'b0 : error_status[0]);
            
            pending_a <= next_pending_a;
            masked_a <= next_masked_a;
            int_id_a <= next_id_a;
            int_valid_a <= next_valid_a;
            error_status[0] <= next_error_status[0];
        end
    end
    
    // Clock domain B
    always @(posedge clk_b or negedge reset_n) begin
        if (!reset_n) begin
            pending_b <= 8'h00;
            masked_b <= 8'h00;
            int_id_b <= 3'd0;
            int_valid_b <= 1'b0;
            error_status[1] <= 1'b0;
        end else begin
            next_pending_b = pending_b | irq_b;
            next_masked_b = next_pending_b & mask;
            next_id_b = encode_id(next_masked_b);
            
            // Optimized state update logic
            next_valid_b = (|next_masked_b) ? !int_valid_b : int_valid_b;
            if (!int_valid_b && |next_masked_b) begin
                next_pending_b[next_id_b] = 1'b0;
            end
            
            // Optimized error detection
            next_error_status[1] = (int_valid_a && int_valid_b && (int_id_a != int_id_b)) ? 1'b1 : 
                                 (err_clear ? 1'b0 : error_status[1]);
            
            pending_b <= next_pending_b;
            masked_b <= next_masked_b;
            int_id_b <= next_id_b;
            int_valid_b <= next_valid_b;
            error_status[1] <= next_error_status[1];
        end
    end
    
    function [2:0] encode_id;
        input [7:0] irqs;
        reg [2:0] result;
        begin
            casez (irqs)
                8'b1???????: result = 3'd7;
                8'b01??????: result = 3'd6;
                8'b001?????: result = 3'd5;
                8'b0001????: result = 3'd4;
                8'b00001???: result = 3'd3;
                8'b000001??: result = 3'd2;
                8'b0000001?: result = 3'd1;
                8'b00000001: result = 3'd0;
                default: result = 3'd0;
            endcase
            encode_id = result;
        end
    endfunction

endmodule